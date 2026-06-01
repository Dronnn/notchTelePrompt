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

    /// writes every script as a UTF-8 .txt into the chosen directory, reusing the same encoding as the
    /// single-script export. filenames are derived from each title, sanitized for the filesystem and
    /// de-duplicated on collision; line breaks are preserved by writing the stored text verbatim.
    /// no-op when there are no scripts; surfaces a single error message on failure.
    func exportAllScripts(to directory: URL) async {
        // clear any prior unrelated error so a stale message can't surface as a false export-all failure.
        errorMessage = nil
        isExporting = true
        defer { isExporting = false }
        // balance sandbox access for the panel-vended directory around the write loop. a false return
        // is fine: the panel grants implicit access, so we still attempt and just skip the stop.
        let scoped = directory.startAccessingSecurityScopedResource()
        defer { if scoped { directory.stopAccessingSecurityScopedResource() } }
        do {
            let scripts = try store.fetchAll()
            guard !scripts.isEmpty else {
                return
            }
            // build (filename, data) pairs on the main actor: Script is not Sendable, so nothing
            // model-backed crosses into the detached write.
            var usedNames: Set<String> = []
            let files: [(name: String, data: Data)] = scripts.map { script in
                let name = Self.uniqueFileName(for: script.title, in: directory, usedNames: &usedNames)
                return (name, ScriptTextCore.fileData(for: script.text, format: .txt))
            }
            try await Task.detached {
                for file in files {
                    let url = directory.appending(path: file.name)
                    try file.data.write(to: url, options: .atomic)
                }
            }.value
        } catch {
            errorMessage = ImportExportError.exportFailed(underlying: error).localizedDescription
        }
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

    /// builds a filesystem-safe ".txt" filename from a title, falling back to "Untitled", and appends a
    /// " 2", " 3" suffix when a base name collides so export-all never overwrites a file. collisions are
    /// matched case-insensitively (APFS is case-insensitive by default) against both names already used
    /// in this run and files already present in the destination directory.
    private static func uniqueFileName(
        for title: String,
        in directory: URL,
        usedNames: inout Set<String>
    ) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let illegal = CharacterSet(charactersIn: "/\\:")
        let sanitized = trimmed
            .components(separatedBy: illegal)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base = sanitized.isEmpty ? String(localized: "Untitled") : sanitized

        var candidate = base
        var index = 2
        while
            usedNames.contains(candidate.lowercased())
            || FileManager.default.fileExists(atPath: directory.appending(path: "\(candidate).txt").path)
        {
            candidate = "\(base) \(index)"
            index += 1
        }
        usedNames.insert(candidate.lowercased())
        return "\(candidate).txt"
    }
}
