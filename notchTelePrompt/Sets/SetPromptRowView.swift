//
//  SetPromptRowView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a single ordered prompt row inside a set, shown as "N. Title" with a 1-based position.
struct SetPromptRowView: View {
    let position: Int
    let script: Script

    var body: some View {
        HStack {
            Text(position, format: .number)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Text(script.title.isEmpty ? "Untitled" : script.title)
                .lineLimit(1)
        }
    }
}
