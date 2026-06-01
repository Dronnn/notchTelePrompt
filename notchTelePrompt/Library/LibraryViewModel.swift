//
//  LibraryViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// drives the script library list: search, sort, recent scripts and library mutations.
@MainActor
@Observable
final class LibraryViewModel {
    private(set) var scripts: [Script] = []
    private(set) var recentScripts: [Script] = []

    var searchText = "" {
        didSet { refresh() }
    }

    var sortOrder: ScriptSortOrder = .updatedDescending {
        didSet { refresh() }
    }

    var selectedScript: Script?
    var errorMessage: String?

    /// notified with a script's id immediately after it is deleted, so observers (e.g. the prompter)
    /// can drop any reference to it.
    var onScriptDeleted: ((UUID) -> Void)?

    private let store: ScriptStore

    init(store: ScriptStore) {
        self.store = store
        refresh()
    }

    // MARK: - Loading

    func refresh() {
        do {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            scripts = trimmed.isEmpty
                ? try store.fetchAll(sortedBy: sortOrder)
                : try store.search(searchText, sortedBy: sortOrder)
            recentScripts = try store.recent(limit: 5)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mutations

    @discardableResult
    func newScript() throws -> Script {
        let script = try store.create()
        refresh()
        selectedScript = script
        return script
    }

    func delete(_ script: Script) throws {
        let deletedID = script.id
        if selectedScript?.id == deletedID {
            selectedScript = nil
        }
        try store.delete(script)
        refresh()
        onScriptDeleted?(deletedID)
    }

    @discardableResult
    func duplicate(_ script: Script) throws -> Script {
        let copy = try store.duplicate(script)
        refresh()
        selectedScript = copy
        return copy
    }

    func rename(_ script: Script, to title: String) throws {
        try store.update(script, title: title)
        refresh()
    }

    func toggleFavorite(_ script: Script) throws {
        try store.toggleFavorite(script)
        refresh()
    }
}
