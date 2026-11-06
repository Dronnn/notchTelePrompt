//
//  TipStore.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Observation
import StoreKit

/// listens for this app's consumable tip transactions and exposes feedback for the support screen.
/// keep one store alive for the app session so approvals that arrive later are still handled.
@MainActor
@Observable
final class TipStore {
    static let productIDs = [
        "com.mrmaier.notchTelePrompt.tip.small",
        "com.mrmaier.notchTelePrompt.tip.medium",
        "com.mrmaier.notchTelePrompt.tip.large",
        "com.mrmaier.notchTelePrompt.tip.generous",
        "com.mrmaier.notchTelePrompt.tip.patron",
        "com.mrmaier.notchTelePrompt.tip.extraordinary"
    ]

    private(set) var feedback: TipFeedback?
    /// products loaded from the App Store or the local StoreKit test configuration.
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var productsErrorMessage: String?

    @ObservationIgnored private var observerTask: Task<Void, Never>?
    @ObservationIgnored private var handledTransactionIDs: Set<UInt64> = []

    init() {
        observerTask = Task { [weak self] in
            await self?.processUnfinishedTransactions()
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
                await self?.process(result)
            }
        }
    }

    deinit {
        observerTask?.cancel()
    }

    // MARK: - Products

    /// loads the tip catalog for the support screen. an empty catalog is surfaced to the user
    /// rather than leaving the donation screen blank.
    func loadProducts() async {
        isLoadingProducts = true
        productsErrorMessage = nil
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { $0.price < $1.price }
            if loaded.isEmpty {
                productsErrorMessage = String(localized: "Donations are unavailable right now.")
            }
        } catch {
            products = []
            productsErrorMessage = String(localized: "Donations are unavailable right now.")
        }
    }

    // MARK: - Purchase feedback

    /// handles a result from StoreKit's native product views.
    func handlePurchaseResult(
        _ result: Result<Product.PurchaseResult, any Error>,
        for product: Product
    ) async {
        guard Self.productIDs.contains(product.id) else { return }
        switch result {
        case let .success(.success(verification)):
            guard case let .verified(transaction) = verification, transaction.productID == product.id else {
                feedback = .failed
                return
            }
            await accept(transaction)
        case .success(.pending):
            feedback = .pending
        case .success(.userCancelled):
            break
        case let .failure(error):
            guard !Self.isCancellation(error) else { break }
            feedback = .failed
        @unknown default:
            feedback = .failed
        }
    }

    func dismissFeedback() {
        feedback = nil
    }

    // MARK: - Transactions

    private func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            guard !Task.isCancelled else { break }
            await process(result)
        }
    }

    private func process(_ result: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = result else { return }
        await accept(transaction)
    }

    private func accept(_ transaction: Transaction) async {
        guard
            Self.productIDs.contains(transaction.productID),
            transaction.productType == .consumable
        else { return }
        if transaction.revocationDate == nil, handledTransactionIDs.insert(transaction.id).inserted {
            feedback = .thankYou
        }
        await transaction.finish()
    }

    private static func isCancellation(_ error: any Error) -> Bool {
        if error is CancellationError {
            return true
        }
        if let storeKitError = error as? StoreKitError, case .userCancelled = storeKitError {
            return true
        }
        return false
    }
}
