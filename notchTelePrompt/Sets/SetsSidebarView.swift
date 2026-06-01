//
//  SetsSidebarView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// sidebar listing the prompt sets with create, rename, delete, duplicate and active-set marking.
/// mirrors LibraryView's structure so the two sidebar modes feel identical.
struct SetsSidebarView: View {
    @Bindable var viewModel: SetsViewModel

    @State private var renameTarget: PromptSet?
    @State private var renameText = ""

    var body: some View {
        List(selection: $viewModel.selectedSet) {
            Section("All Sets") {
                ForEach(viewModel.sets) { set in
                    SetRowContainerView(set: set, viewModel: viewModel, onRename: startRename)
                }
            }
        }
        .overlay {
            if viewModel.sets.isEmpty {
                ContentUnavailableView(
                    "No Sets",
                    systemImage: "rectangle.stack",
                    description: Text("Create a set to group prompts for a session.")
                )
            }
        }
        .toolbar {
            Button("New Set", systemImage: "plus") {
                do {
                    try viewModel.createSet()
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
        .alert("Rename Set", isPresented: renameBinding) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                do {
                    try viewModel.renameSelectedSet(to: renameText)
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
        .alert(
            "Couldn't complete that action",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Rename

    private var renameBinding: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { isPresented in
                if !isPresented {
                    renameTarget = nil
                }
            }
        )
    }

    private func startRename(_ set: PromptSet) {
        // renameSelectedSet renames the current selection, so select the target before opening the alert.
        viewModel.select(set)
        renameTarget = set
        renameText = set.name
    }
}
