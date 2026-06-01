//
//  SetNavigatorRowView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a single navigator row: the 1-based position and the script title, tappable to send the script to
/// the prompter. the currently shown script is highlighted with a subtle fill.
struct SetNavigatorRowView: View {
    let number: Int
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .firstTextBaseline) {
                Text(number, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.6))
                Text(displayTitle)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.white.opacity(0.18) : .clear)
            .clipShape(.rect(cornerRadius: 6))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    /// shows a placeholder for untitled scripts so a blank row never appears.
    private var displayTitle: String {
        title.isEmpty ? String(localized: "Untitled") : title
    }
}
