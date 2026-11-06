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
            StoreView(ids: TipStore.productIDs)
                .storeButton(.hidden, for: .restorePurchases)
                .onInAppPurchaseStart { _ in
                    store.dismissFeedback()
                }
                .onInAppPurchaseCompletion { product, result in
                    await store.handlePurchaseResult(result, for: product)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if let feedback = store.feedback {
                SupportFeedbackView(feedback: feedback)
            }
        }
        .frame(maxWidth: 560, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
