//
//  ImportExportViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// the single coordinator wiring import/export/paste/drag actions to the store and library.
/// owns the AppKit-backed service; surfaces errors and progress for the UI to bind to.
@MainActor
@Observable
final class ImportExportViewModel {
    var errorMessage: String?
    var isImporting = false
    var isExporting = false

    /// holds a dropped file's decoded payload while the new-vs-replace dialog is shown.
    var pendingDrop: DropConfirmationState?

    private let store: ScriptStore
    private let libraryViewModel: LibraryViewModel
    private let service: ImportExportService

    init(
        store: ScriptStore,
        libraryViewModel: LibraryViewModel,
        service: ImportExportService = ImportExportService()
    ) {
        self.store = store
        self.libraryViewModel = libraryViewModel
        self.service = service
    }

    // MARK: - Import

    func importScript() async {
        isImporting = true
        defer { isImporting = false }
        do {
            guard let result = try await service.importFromPanel() else {
                return
            }
            createAndSelect(title: result.title, text: result.text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Clipboard

    func pasteClipboardAsScript() {
        do {
            let result = try service.pasteFromClipboard()
            createAndSelect(title: result.title, text: result.text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Export

    func exportScript(_ script: Script, format: ExportFormat) async {
        isExporting = true
        defer { isExporting = false }
        do {
            try await service.exportToPanel(title: script.title, text: script.text, suggestedFormat: format)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// exports the library's currently selected script; used by the menu-bar Export command.
    func exportSelectedScript(format: ExportFormat = .txt) async {
        guard let script = libraryViewModel.selectedScript else {
            errorMessage = String(localized: "Select a script to export.")
            return
        }
        await exportScript(script, format: format)
    }

    // MARK: - Drag-drop

    func handleDroppedFile(url: URL, into editorViewModel: ScriptEditorViewModel) async {
        do {
            let result = try await service.readFileText(at: url)
            // an empty editor (or no selection) takes the drop directly; otherwise ask before overwriting.
            if editorViewModel.selectedScript == nil || editorViewModel.text.isEmpty {
                createAndSelect(title: result.title, text: result.text)
            } else {
                pendingDrop = DropConfirmationState(url: url, title: result.title, text: result.text)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDropAsNewScript() {
        guard let pending = pendingDrop else {
            return
        }
        pendingDrop = nil
        createAndSelect(title: pending.title, text: pending.text)
    }

    func confirmDropReplacingContents(in editorViewModel: ScriptEditorViewModel) {
        guard let pending = pendingDrop, let script = editorViewModel.selectedScript else {
            pendingDrop = nil
            return
        }
        pendingDrop = nil
        do {
            try store.update(script, title: pending.title, text: pending.text)
            // drop the editor's unsaved edits so the reselection below cannot flush stale text
            // over the content we just wrote; the user chose to replace, so those edits are discarded.
            editorViewModel.cancelPendingEdits()
            // refresh the editor view model from the mutated script and the library list.
            editorViewModel.selectedScript = nil
            editorViewModel.selectedScript = script
            libraryViewModel.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelDrop() {
        pendingDrop = nil
    }

    // MARK: - Helpers

    private func createAndSelect(title: String, text: String) {
        do {
            let script = try store.create(title: title, text: text)
            libraryViewModel.refresh()
            libraryViewModel.selectedScript = script
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
