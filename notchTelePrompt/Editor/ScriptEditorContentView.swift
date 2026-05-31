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

            StatsFooterView(
                wordCount: viewModel.wordCount,
                charCount: viewModel.charCount,
                readingTime: viewModel.readingTime
            )
        }
        .padding()
        .toolbar {
            Button("Start Prompter", systemImage: "play.fill") {}
                .disabled(true)
                .help("Available once the prompter overlay is built (Phase 4).")
        }
    }
}
