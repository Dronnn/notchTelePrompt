//
//  TipJarTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import StoreKit
import StoreKitTest
import Testing

@Suite(.serialized)
@MainActor
struct TipJarTests {
    @Test
    func localCatalogContainsTheConfiguredConsumables() async throws {
        try await withSession { _ in
            let products = try await loadProducts()
            #expect(products.count == TipStore.productIDs.count)
            #expect(Set(products.map(\.id)) == Set(TipStore.productIDs))
            #expect(products.allSatisfy { $0.type == .consumable })
            #expect(products.allSatisfy { !$0.displayPrice.isEmpty })

            let prices = Dictionary(uniqueKeysWithValues: products.map {
                ($0.id, NSDecimalNumber(decimal: $0.price).stringValue)
            })
            #expect(prices == [
                "com.mrmaier.notchTelePrompt.tip.small": "2.99",
                "com.mrmaier.notchTelePrompt.tip.medium": "4.99",
                "com.mrmaier.notchTelePrompt.tip.large": "7.99",
                "com.mrmaier.notchTelePrompt.tip.generous": "19.99",
                "com.mrmaier.notchTelePrompt.tip.patron": "49.99",
                "com.mrmaier.notchTelePrompt.tip.extraordinary": "99.99"
            ])
        }
    }

    @Test
    func tipStoreLoadsTheDonationCatalog() async throws {
        try await withSession { _ in
            let store = TipStore()
            await store.loadProducts()

            #expect(store.products.count == TipStore.productIDs.count)
            #expect(store.productsErrorMessage == nil)
            #expect(store.products.map(\.id).sorted() == TipStore.productIDs.sorted())
        }
    }

    @Test
    func runSchemeReferencesTheLocalStoreKitConfiguration() throws {
        let repositoryRoot = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let schemeURL = repositoryRoot
            .appending(path: "notchTelePrompt.xcodeproj/xcshareddata/xcschemes/notchTelePrompt.xcscheme")
        let scheme = try String(contentsOf: schemeURL, encoding: .utf8)

        let pattern = #"<StoreKitConfigurationFileReference\s+identifier = "([^"]+)""#
        let regex = try NSRegularExpression(pattern: pattern)
        let fullRange = NSRange(scheme.startIndex..<scheme.endIndex, in: scheme)
        let match = try #require(regex.firstMatch(in: scheme, range: fullRange))
        let identifierRange = try #require(Range(match.range(at: 1), in: scheme))
        let identifier = String(scheme[identifierRange])

        let projectDirectory = repositoryRoot.appending(
            path: "notchTelePrompt.xcodeproj",
            directoryHint: .isDirectory
        )
        let resolved = URL(filePath: identifier, relativeTo: projectDirectory).standardizedFileURL
        let configurationURL = repositoryRoot
            .appending(path: "notchTelePrompt/Resources/TipJar.storekit")
            .standardizedFileURL

        #expect(resolved == configurationURL)
        #expect(FileManager.default.fileExists(atPath: resolved.path))
    }

    @Test
    func unfinishedVerifiedTipIsAcknowledgedAndFinished() async throws {
        try await withSession { session in
            // the app host has its own TipStore, so listen before the purchase instead of relying on
            // a backlog the host may already have finished
            let store = TipStore()
            let transaction = try await session.buyProduct(identifier: TipStore.productIDs[0])

            #expect(await eventually { store.feedback == .thankYou })
            #expect(await eventually {
                let unfinished = await unfinishedTransactionIDs()
                return !unfinished.contains(transaction.id)
            })
        }
    }

    @Test
    func pendingFeedbackBecomesThankYouWhenAnApprovedTransactionArrives() async throws {
        try await withSession { session in
            let products = try await loadProducts()
            let product = try #require(products.first)
            let store = TipStore()

            // the pending UI state is produced by a real Ask to Buy purchase, which can't run in an
            // isolated unit-test host; verify the state transition when the approved transaction arrives.
            await store.handlePurchaseResult(.success(.pending), for: product)
            #expect(store.feedback == .pending)

            let transaction = try await session.buyProduct(identifier: product.id)

            #expect(await eventually { store.feedback == .thankYou })
            #expect(await eventually {
                let unfinished = await unfinishedTransactionIDs()
                return !unfinished.contains(transaction.id)
            })
        }
    }

    @Test
    func purchaseOutcomesMapToFeedbackAndCancellationStaysQuiet() async throws {
        try await withSession { _ in
            let products = try await loadProducts()
            let product = try #require(products.first)
            let store = TipStore()

            await store.handlePurchaseResult(.success(.pending), for: product)
            #expect(store.feedback == .pending)

            await store.handlePurchaseResult(.success(.userCancelled), for: product)
            #expect(store.feedback == .pending)

            await store.handlePurchaseResult(.failure(StoreKitError.userCancelled), for: product)
            #expect(store.feedback == .pending)

            await store.handlePurchaseResult(.failure(URLError(.notConnectedToInternet)), for: product)
            #expect(store.feedback == .failed)

            store.dismissFeedback()
            #expect(store.feedback == nil)
        }
    }

    // MARK: - Helpers

    private func withSession(_ body: (SKTestSession) async throws -> Void) async throws {
        let session = try SKTestSession(contentsOf: Self.configurationURL)
        session.resetToDefaultState()
        session.clearTransactions()
        // pin the fixture's US storefront so prices aren't converted to the host's App Store region
        session.storefront = "USA"
        session.locale = Locale(identifier: "en_US")
        session.disableDialogs = true
        do {
            try await body(session)
        } catch {
            session.resetToDefaultState()
            session.clearTransactions()
            throw error
        }
        session.resetToDefaultState()
        session.clearTransactions()
    }

    /// StoreKit's test session can need a moment before products become visible; retry briefly so
    /// a cold test process doesn't turn an environment race into a false failure.
    private func loadProducts() async throws -> [Product] {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        while clock.now < deadline {
            let products = try await Product.products(for: TipStore.productIDs)
            if !products.isEmpty {
                return products
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return try await Product.products(for: TipStore.productIDs)
    }

    private func unfinishedTransactionIDs() async -> Set<UInt64> {
        var identifiers: Set<UInt64> = []
        for await result in Transaction.unfinished {
            guard case let .verified(transaction) = result else { continue }
            identifiers.insert(transaction.id)
        }
        return identifiers
    }

    private func eventually(_ condition: @MainActor () async -> Bool) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        while clock.now < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(25))
        }
        return await condition()
    }

    private static var configurationURL: URL {
        guard let url = Bundle.main.url(forResource: "TipJar", withExtension: "storekit") else {
            fatalError("TipJar.storekit is missing from the app bundle")
        }
        return url
    }
}
