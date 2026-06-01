//
//  MainView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftData
import SwiftUI

/// root window content: the library sidebar and the script editor detail.
/// the library view model owns the single source of truth for the current selection.
struct MainView: View {
    @State private var libraryViewModel: LibraryViewModel
    @State private var editorViewModel: ScriptEditorViewModel
    @State private var importExportViewModel: ImportExportViewModel

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    private let modelContainer: ModelContainer
    private let onStartPrompter: ((Script) -> Void)?

    init(
        environment: AppEnvironment,
        libraryViewModel: LibraryViewModel,
        importExportViewModel: ImportExportViewModel,
        onStartPrompter: ((Script) -> Void)? = nil
    ) {
        _libraryViewModel = State(initialValue: libraryViewModel)
        _editorViewModel = State(initialValue: ScriptEditorViewModel(store: environment.scriptStore))
        _importExportViewModel = State(initialValue: importExportViewModel)
        modelContainer = environment.modelContainer
        self.onStartPrompter = onStartPrompter
    }

    var body: some View {
        NavigationSplitView {
            LibraryView(viewModel: libraryViewModel)
        } detail: {
            ScriptEditorView(
                viewModel: editorViewModel,
                importExportViewModel: importExportViewModel,
                onStartPrompter: onStartPrompter
            )
        }
        .onChange(of: libraryViewModel.selectedScript) { _, newValue in
            editorViewModel.selectedScript = newValue
        }
        .modelContainer(modelContainer)
        .sheet(isPresented: .init(get: { !hasSeenWelcome }, set: { _ in })) {
            WelcomeView()
        }
        .alert(
            "Couldn't complete that action",
            isPresented: Binding(
                get: { importExportViewModel.errorMessage != nil },
                set: { if !$0 { importExportViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importExportViewModel.errorMessage ?? "")
        }
        .confirmationDialog(
            "Import dropped file",
            isPresented: Binding(
                get: { importExportViewModel.pendingDrop != nil },
                set: { if !$0 { importExportViewModel.cancelDrop() } }
            ),
            titleVisibility: .visible
        ) {
            Button("New Script") { importExportViewModel.confirmDropAsNewScript() }
            Button("Replace Contents", role: .destructive) {
                importExportViewModel.confirmDropReplacingContents(in: editorViewModel)
            }
            Button("Cancel", role: .cancel) { importExportViewModel.cancelDrop() }
        } message: {
            Text("Create a new script from this file, or replace the current script's contents?")
        }
    }
}
