//
//  ScriptEditorContentView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the editing surface shown when a script is selected: title field, body editor, live stats and the prompter toolbar
/// action.
struct ScriptEditorContentView: View {
    @Bindable var viewModel: ScriptEditorViewModel
    let importExportViewModel: ImportExportViewModel
    let onStartPrompter: ((Script) -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Title", text: $viewModel.title)
                .textFieldStyle(.plain)
                .font(.title2)

            Divider()

            TextEditor(text: $viewModel.text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .overlay(alignment: .topLeading) {
                    if viewModel.text.isEmpty {
                        Text("Paste your script here.")
                            .foregroundStyle(.tertiary)
                            .allowsHitTesting(false)
                    }
                }

            Divider()

            HStack {
                StatsFooterView(
                    wordCount: viewModel.wordCount,
                    charCount: viewModel.charCount,
                    readingTime: viewModel.readingTime
                )
                FontSizeControlView(viewModel: viewModel)
            }
        }
        .padding()
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else {
                return false
            }
            Task { await importExportViewModel.handleDroppedFile(url: url, into: viewModel) }
            return true
        }
        .toolbar {
            if let script = viewModel.selectedScript {
                Menu("Export", systemImage: "arrow.up.doc") {
                    Button(ExportFormat.txt.localizedLabel) {
                        Task { await importExportViewModel.exportScript(script, format: .txt) }
                    }
                    Button(ExportFormat.md.localizedLabel) {
                        Task { await importExportViewModel.exportScript(script, format: .md) }
                    }
                }
            }

            Button("Start Prompter", systemImage: "play.fill") {
                if let script = viewModel.selectedScript {
                    // flush the debounced autosave so the prompter starts with the current edited text.
                    viewModel.saveImmediately()
                    onStartPrompter?(script)
                }
            }
            .disabled(
                viewModel.selectedScript == nil
                    || viewModel.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .keyboardShortcut("r", modifiers: .command)
        }
    }
}
