//
//  ScriptRowContainerView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// wraps a single library row with its selection tag and context-menu actions.
struct ScriptRowContainerView: View {
    let script: Script
    let viewModel: LibraryViewModel
    var onRename: (Script) -> Void

    var body: some View {
        ScriptRowView(script: script)
            .tag(script)
            .contextMenu {
                Button("Duplicate", systemImage: "doc.on.doc") {
                    do {
                        try viewModel.duplicate(script)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
                Button("Rename", systemImage: "pencil") {
                    onRename(script)
                }
                Button(
                    script.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: script.isFavorite ? "star.slash" : "star"
                ) {
                    do {
                        try viewModel.toggleFavorite(script)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    do {
                        try viewModel.delete(script)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
    }
}
