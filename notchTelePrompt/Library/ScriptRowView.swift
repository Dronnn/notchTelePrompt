//
//  ScriptRowView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a single row in the script library list.
/// reads the Script directly so SwiftUI observes its properties for live updates.
struct ScriptRowView: View {
    let script: Script

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(script.title.isEmpty ? "Untitled" : script.title)
                    .lineLimit(1)
                Text(script.updatedAt, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if script.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")
            }
        }
    }
}
