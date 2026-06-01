//
//  LibraryView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// sidebar listing the script library with search, sort, recents and per-row actions.
struct LibraryView: View {
    @Bindable var viewModel: LibraryViewModel

    @State private var renameTarget: Script?
    @State private var renameText = ""

    var body: some View {
        List(selection: $viewModel.selectedScript) {
            if !viewModel.recentScripts.isEmpty, viewModel.searchText.isEmpty {
                Section("Recent") {
                    ForEach(viewModel.recentScripts) { script in
                        ScriptRowContainerView(script: script, viewModel: viewModel, onRename: startRename)
                    }
                }
            }

            Section("All Scripts") {
                ForEach(viewModel.scripts) { script in
                    ScriptRowContainerView(script: script, viewModel: viewModel, onRename: startRename)
                }
            }
        }
        .searchable(text: $viewModel.searchText)
        .overlay {
            if viewModel.scripts.isEmpty, viewModel.searchText.isEmpty {
                ContentUnavailableView(
                    "No Scripts",
                    systemImage: "doc.text",
                    description: Text("Create your first script to get started.")
                )
            }
        }
        .toolbar {
            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(ScriptSortOrder.allCases, id: \.self) { order in
                    Text(order.title).tag(order)
                }
            }
            .accessibilityLabel("Sort scripts")

            Button("New Script", systemImage: "plus") {
                do {
                    try viewModel.newScript()
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
        .alert("Rename Script", isPresented: renameBinding) {
            TextField("Title", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                if let renameTarget {
                    do {
                        try viewModel.rename(renameTarget, to: renameText)
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
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

    private func startRename(_ script: Script) {
        renameTarget = script
        renameText = script.title
    }
}
