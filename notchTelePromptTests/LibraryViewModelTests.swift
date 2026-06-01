//
//  LibraryViewModelTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import SwiftData
import Testing

@MainActor
struct LibraryViewModelTests {
    /// builds a fresh in-memory store for each test so cases stay isolated.
    private func makeStore() throws -> ScriptStore {
        let container = try ModelContainerFactory.makeInMemory()
        return ScriptStore(container: container)
    }

    // MARK: - Init

    @Test
    func initRefreshesFromStore() throws {
        let store = try makeStore()
        try store.create(title: "Existing")
        let viewModel = LibraryViewModel(store: store)
        #expect(viewModel.scripts.count == 1)
        #expect(viewModel.scripts.first?.title == "Existing")
    }

    // MARK: - New

    @Test
    func newScriptAddsAndSelects() throws {
        let store = try makeStore()
        let viewModel = LibraryViewModel(store: store)
        let created = try viewModel.newScript()
        #expect(viewModel.scripts.contains { $0.id == created.id })
        #expect(viewModel.selectedScript?.id == created.id)
    }

    // MARK: - Delete

    @Test
    func deleteRemovesAndClearsSelectionWhenSelected() throws {
        let store = try makeStore()
        let viewModel = LibraryViewModel(store: store)
        let script = try viewModel.newScript()
        try viewModel.delete(script)
        #expect(viewModel.scripts.isEmpty)
        #expect(viewModel.selectedScript == nil)
    }

    @Test
    func deleteKeepsSelectionWhenDifferentScript() throws {
        let store = try makeStore()
        let viewModel = LibraryViewModel(store: store)
        let selected = try viewModel.newScript()
        let other = try store.create(title: "Other")
        viewModel.refresh()
        viewModel.selectedScript = selected
        try viewModel.delete(other)
        #expect(viewModel.selectedScript?.id == selected.id)
        #expect(!viewModel.scripts.contains { $0.id == other.id })
    }

    @Test
    func deleteNotifiesObserverWithDeletedID() throws {
        let store = try makeStore()
        let viewModel = LibraryViewModel(store: store)
        let script = try viewModel.newScript()
        let deletedID = script.id
        var notifiedID: UUID?
        viewModel.onScriptDeleted = { notifiedID = $0 }
        try viewModel.delete(script)
        #expect(notifiedID == deletedID)
    }

    // MARK: - Duplicate

    @Test
    func duplicateAddsAndSelectsCopy() throws {
        let store = try makeStore()
        let viewModel = LibraryViewModel(store: store)
        let original = try store.create(title: "Talk", text: "body")
        viewModel.refresh()
        let copy = try viewModel.duplicate(original)
        #expect(copy.id != original.id)
        #expect(copy.title == "Talk copy")
        #expect(viewModel.selectedScript?.id == copy.id)
        #expect(viewModel.scripts.count == 2)
    }

    // MARK: - Rename

    @Test
    func renameUpdatesTitle() throws {
        let store = try makeStore()
        let viewModel = LibraryViewModel(store: store)
        let script = try store.create(title: "Old")
        viewModel.refresh()
        try viewModel.rename(script, to: "New")
        #expect(script.title == "New")
    }

    // MARK: - Favorite

    @Test
    func toggleFavoriteFlipsAndRefetches() throws {
        let store = try makeStore()
        let viewModel = LibraryViewModel(store: store)
        let script = try store.create(title: "Fav")
        viewModel.refresh()
        #expect(script.isFavorite == false)
        try viewModel.toggleFavorite(script)
        #expect(script.isFavorite == true)
        #expect(viewModel.scripts.first { $0.id == script.id }?.isFavorite == true)
    }

    // MARK: - Search

    @Test
    func searchTextFiltersResults() throws {
        let store = try makeStore()
        try store.create(title: "Morning Show")
        try store.create(title: "Evening")
        let viewModel = LibraryViewModel(store: store)
        viewModel.searchText = "morning"
        #expect(viewModel.scripts.count == 1)
        #expect(viewModel.scripts.first?.title == "Morning Show")
    }

    @Test
    func emptySearchReturnsAll() throws {
        let store = try makeStore()
        try store.create(title: "A")
        try store.create(title: "B")
        let viewModel = LibraryViewModel(store: store)
        viewModel.searchText = "A"
        #expect(viewModel.scripts.count == 1)
        viewModel.searchText = "   "
        #expect(viewModel.scripts.count == 2)
    }

    // MARK: - Sort

    @Test
    func sortOrderRefetches() throws {
        let store = try makeStore()
        try store.create(title: "Charlie")
        try store.create(title: "alpha")
        try store.create(title: "Bravo")
        let viewModel = LibraryViewModel(store: store)
        viewModel.sortOrder = .titleAscending
        #expect(viewModel.scripts.map(\.title) == ["alpha", "Bravo", "Charlie"])
    }

    // MARK: - Recent

    @Test
    func recentScriptsEmptyWhenNoneUsed() throws {
        let store = try makeStore()
        try store.create(title: "Never used")
        let viewModel = LibraryViewModel(store: store)
        #expect(viewModel.recentScripts.isEmpty)
    }

    @Test
    func recentScriptsSortedByLastUsedDescending() throws {
        let store = try makeStore()
        let first = try store.create(title: "First")
        let second = try store.create(title: "Second")
        let base = Date(timeIntervalSince1970: 1_000_000)
        try store.markUsed(first, at: base)
        try store.markUsed(second, at: base.addingTimeInterval(60))
        let viewModel = LibraryViewModel(store: store)
        #expect(viewModel.recentScripts.map(\.id) == [second.id, first.id])
    }
}
