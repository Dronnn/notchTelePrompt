//
//  SetRowView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a single row in the sets sidebar list.
/// reads the PromptSet directly so SwiftUI observes its properties for live updates.
struct SetRowView: View {
    let set: PromptSet
    let isActive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(set.name.isEmpty ? "Untitled Set" : set.name)
                    .lineLimit(1)
                Text(set.scriptIDs.count, format: .number)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(set.scriptIDs.count) prompts")
            }
            Spacer()
            if isActive {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Active")
            }
        }
    }
}
