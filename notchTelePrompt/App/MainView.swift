//
//  MainView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftData
import SwiftUI

/// root window content: a section switch between the script library/editor and the prompt sets editor.
/// the library and sets view models each own the single source of truth for their selection.
struct MainView: View {
    @State private var section: MainSection = .library
    @State private var libraryViewModel: LibraryViewModel
    @State private var editorViewModel: ScriptEditorViewModel
    @State private var importExportViewModel: ImportExportViewModel
    @State private var setsViewModel: SetsViewModel

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    private let modelContainer: ModelContainer
    private let onStartPrompter: ((Script) -> Void)?

    init(
        environment: AppEnvironment,
        libraryViewModel: LibraryViewModel,
        importExportViewModel: ImportExportViewModel,
        setsViewModel: SetsViewModel,
        onStartPrompter: ((Script) -> Void)? = nil
    ) {
        _libraryViewModel = State(initialValue: libraryViewModel)
        _editorViewModel = State(initialValue: ScriptEditorViewModel(
            store: environment.scriptStore,
            preferences: environment.preferencesStore
        ))
        _importExportViewModel = State(initialValue: importExportViewModel)
        _setsViewModel = State(initialValue: setsViewModel)
        modelContainer = environment.modelContainer
        self.onStartPrompter = onStartPrompter
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Picker("Section", selection: $section) {
                    ForEach(MainSection.allCases) { section in
                        Label(section.title, systemImage: section.systemImage).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                // keep the label hidden visually but expose it to voiceover
                .labelsHidden()
                .accessibilityLabel("Navigation section")
                .accessibilityValue(section.title)
                .padding()

                switch section {
                case .library:
                    LibraryView(viewModel: libraryViewModel)
                case .sets:
                    SetsSidebarView(viewModel: setsViewModel)
                }
            }
        } detail: {
            switch section {
            case .library:
                ScriptEditorView(
                    viewModel: editorViewModel,
                    importExportViewModel: importExportViewModel,
                    onStartPrompter: onStartPrompter
                )
            case .sets:
                SetDetailView(viewModel: setsViewModel)
            }
        }
        .onChange(of: libraryViewModel.selectedScript) { _, newValue in
            editorViewModel.selectedScript = newValue
        }
        .onChange(of: section) { _, newValue in
            // entering the sets section: pick up any changes made elsewhere (e.g. the navigator).
            if newValue == .sets {
                setsViewModel.refreshSets()
            }
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
