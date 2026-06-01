//
//  SetRowContainerView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// wraps a single sets-sidebar row with its selection tag and context-menu actions.
struct SetRowContainerView: View {
    let set: PromptSet
    let viewModel: SetsViewModel
    var onRename: (PromptSet) -> Void

    var body: some View {
        SetRowView(set: set, isActive: viewModel.activeSetID == set.id)
            .tag(set)
            .contextMenu {
                Button("Use in Navigator", systemImage: "dot.radiowaves.left.and.right") {
                    viewModel.makeActive(set)
                }
                Divider()
                Button("Duplicate", systemImage: "doc.on.doc") {
                    do {
                        try viewModel.duplicateSet(set)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
                Button("Rename", systemImage: "pencil") {
                    onRename(set)
                }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive) {
                    do {
                        try viewModel.deleteSet(set)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            }
    }
}
