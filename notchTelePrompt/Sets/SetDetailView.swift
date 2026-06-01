//
//  SetDetailView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// detail view for the selected set: rename, the ordered prompt list with drag-reorder and remove,
/// an add-from-library menu, and a "use in navigator" action that marks the set active.
struct SetDetailView: View {
    @Bindable var viewModel: SetsViewModel

    var body: some View {
        if let set = viewModel.selectedSet {
            SetDetailContentView(viewModel: viewModel, set: set)
        } else {
            ContentUnavailableView(
                "No Set Selected",
                systemImage: "rectangle.stack",
                description: Text("Select a set to edit its prompts.")
            )
        }
    }
}

/// the editing surface shown once a set is selected. split out so it can read the selected set as a value.
private struct SetDetailContentView: View {
    @Bindable var viewModel: SetsViewModel
    let set: PromptSet

    var body: some View {
        List {
            if viewModel.scriptsInSelectedSet.isEmpty {
                ContentUnavailableView(
                    "No Prompts",
                    systemImage: "text.badge.plus",
                    description: Text("Add prompts from your library to build this set.")
                )
            } else {
                Section("Prompts") {
                    // iterate over indices (a RandomAccessCollection of Int) so .onMove is available and the
                    // 1-based row number is derived directly; matches the navigator's list pattern.
                    ForEach(viewModel.scriptsInSelectedSet.indices, id: \.self) { index in
                        let script = viewModel.scriptsInSelectedSet[index]
                        SetPromptRowView(position: index + 1, script: script)
                            .swipeActions {
                                Button("Remove from Set", systemImage: "minus.circle", role: .destructive) {
                                    remove(script)
                                }
                            }
                            .contextMenu {
                                Button("Remove from Set", systemImage: "minus.circle", role: .destructive) {
                                    remove(script)
                                }
                            }
                    }
                    .onMove { fromOffsets, toOffset in
                        do {
                            try viewModel.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
        .navigationTitle(set.name.isEmpty ? "Untitled Set" : set.name)
        .toolbar {
            AddPromptsMenu(viewModel: viewModel)

            Button("Use in Navigator", systemImage: "dot.radiowaves.left.and.right") {
                viewModel.makeActive(set)
            }
            .disabled(viewModel.activeSetID == set.id)
        }
    }

    // MARK: - Actions

    private func remove(_ script: Script) {
        do {
            try viewModel.removeScript(script)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

/// toolbar menu listing the library scripts not yet in the selected set; picking one adds it.
private struct AddPromptsMenu: View {
    let viewModel: SetsViewModel

    var body: some View {
        Menu("Add Prompts", systemImage: "plus") {
            if viewModel.availableScripts.isEmpty {
                Text("No more prompts to add")
            } else {
                ForEach(viewModel.availableScripts) { script in
                    Button(script.title.isEmpty ? "Untitled" : script.title) {
                        do {
                            try viewModel.addScript(script)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
        .disabled(viewModel.availableScripts.isEmpty)
    }
}
