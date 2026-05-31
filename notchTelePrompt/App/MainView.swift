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

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    private let modelContainer: ModelContainer

    init(environment: AppEnvironment) {
        _libraryViewModel = State(initialValue: LibraryViewModel(store: environment.scriptStore))
        _editorViewModel = State(initialValue: ScriptEditorViewModel(store: environment.scriptStore))
        modelContainer = environment.modelContainer
    }

    var body: some View {
        NavigationSplitView {
            LibraryView(viewModel: libraryViewModel)
        } detail: {
            ScriptEditorView(viewModel: editorViewModel)
        }
        .onChange(of: libraryViewModel.selectedScript) { _, newValue in
            editorViewModel.selectedScript = newValue
        }
        .modelContainer(modelContainer)
        .sheet(isPresented: .init(get: { !hasSeenWelcome }, set: { _ in })) {
            WelcomeView()
        }
    }
}
