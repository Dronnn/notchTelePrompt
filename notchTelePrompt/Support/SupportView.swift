//
//  SupportView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import StoreKit
import SwiftUI

/// optional developer tips. StoreKit supplies product names, descriptions, and storefront prices.
struct SupportView: View {
    let store: TipStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SupportIntroduction()
            Group {
                if store.isLoadingProducts, store.products.isEmpty {
                    ProgressView("Loading donations…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let message = store.productsErrorMessage, store.products.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(message)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await store.loadProducts() }
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.products, id: \.id) { product in
                                SupportProductRow(product: product, store: store)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if let feedback = store.feedback {
                SupportFeedbackView(feedback: feedback)
            }
        }
        .frame(maxWidth: 560, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await store.loadProducts()
        }
    }
}

/// one tip product with its storefront price. using explicit rows keeps the donation screen
/// populated even when the system store view has no layout space in a preferences pane.
private struct SupportProductRow: View {
    let product: Product
    let store: TipStore

    @State private var isPurchasing = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button(product.displayPrice) {
                Task { await purchase() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing)
        }
        .padding(12)
        .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 8))
    }

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            await store.handlePurchaseResult(.success(result), for: product)
        } catch {
            await store.handlePurchaseResult(.failure(error), for: product)
        }
    }
}

private struct SupportIntroduction: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Support NotchPrompter", systemImage: "heart")
                .font(.title2.bold())
            Text("Tips are optional. If you enjoy NotchPrompter, you can leave one to support its development.")
            Text("Tips do not unlock any features.")
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SupportFeedbackView: View {
    let feedback: TipFeedback

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label {
                switch feedback {
                case .pending:
                    Text("Your tip is awaiting approval.")
                case .thankYou:
                    Text("Thank you for supporting NotchPrompter!")
                case .failed:
                    Text("The tip could not be completed. Please try again.")
                }
            } icon: {
                Image(systemName: symbolName)
            }
        }
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var symbolName: String {
        switch feedback {
        case .pending: "clock"
        case .thankYou: "heart.fill"
        case .failed: "exclamationmark.triangle"
        }
    }
}
