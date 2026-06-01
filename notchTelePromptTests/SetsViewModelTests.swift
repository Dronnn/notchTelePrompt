//
//  SetsViewModelTests.swift
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
struct SetsViewModelTests {
    /// builds a fresh in-memory container, two stores over the same context-backing container,
    /// and an isolated UserDefaults suite so cases stay isolated.
    private func makeViewModel() throws -> (
        viewModel: SetsViewModel,
        promptSetStore: PromptSetStore,
        scriptStore: ScriptStore
    ) {
        let container = try ModelContainerFactory.makeInMemory()
        let suiteName = "SetsViewModelTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw SetsViewModelTestsError.defaultsUnavailable
        }
        defaults.removePersistentDomain(forName: suiteName)
        let scriptStore = ScriptStore(modelContext: ModelContext(container))
        let promptSetStore = PromptSetStore(modelContext: ModelContext(container), defaults: defaults)
        let viewModel = SetsViewModel(promptSetStore: promptSetStore, scriptStore: scriptStore)
        return (viewModel, promptSetStore, scriptStore)
    }

    private enum SetsViewModelTestsError: Error {
        case defaultsUnavailable
    }

    // MARK: - Create

    @Test
    func createSetAddsAndSelects() throws {
        let (viewModel, _, _) = try makeViewModel()
        let set = try viewModel.createSet(name: "Show")
        #expect(viewModel.sets.contains { $0.id == set.id })
        #expect(viewModel.selectedSet?.id == set.id)
    }

    // MARK: - Membership

    @Test
    func addScriptAppendsAndExcludesFromAvailable() throws {
        let (viewModel, _, scriptStore) = try makeViewModel()
        let first = try scriptStore.create(title: "First")
        let second = try scriptStore.create(title: "Second")
        let set = try viewModel.createSet(name: "Set")
        viewModel.select(set)
        // both library scripts start out available to add.
        #expect(viewModel.availableScripts.count == 2)
        try viewModel.addScript(first)
        #expect(viewModel.scriptsInSelectedSet.map(\.id) == [first.id])
        // the added script must no longer appear as available; the other still does.
        #expect(viewModel.availableScripts.map(\.id) == [second.id])
    }

    @Test
    func removeScriptDropsItAndReturnsToAvailable() throws {
        let (viewModel, _, scriptStore) = try makeViewModel()
        let script = try scriptStore.create(title: "Only")
        let set = try viewModel.createSet(name: "Set")
        viewModel.select(set)
        try viewModel.addScript(script)
        #expect(viewModel.scriptsInSelectedSet.count == 1)
        try viewModel.removeScript(script)
        #expect(viewModel.scriptsInSelectedSet.isEmpty)
        #expect(viewModel.availableScripts.map(\.id) == [script.id])
    }

    // MARK: - Reorder

    @Test
    func moveReordersSelectedSet() throws {
        let (viewModel, _, scriptStore) = try makeViewModel()
        let a = try scriptStore.create(title: "A")
        let b = try scriptStore.create(title: "B")
        let c = try scriptStore.create(title: "C")
        let set = try viewModel.createSet(name: "Set")
        viewModel.select(set)
        try viewModel.addScript(a)
        try viewModel.addScript(b)
        try viewModel.addScript(c)
        // move the first prompt to the end.
        try viewModel.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        #expect(viewModel.scriptsInSelectedSet.map(\.id) == [b.id, c.id, a.id])
    }

    // MARK: - Selection

    @Test
    func selectLoadsSetContents() throws {
        let (viewModel, promptSetStore, scriptStore) = try makeViewModel()
        let script = try scriptStore.create(title: "Member")
        let set = try promptSetStore.create(name: "Set")
        try promptSetStore.addScript(script.id, to: set)
        viewModel.refreshSets()
        // before selecting, nothing is resolved.
        #expect(viewModel.scriptsInSelectedSet.isEmpty)
        viewModel.select(set)
        #expect(viewModel.scriptsInSelectedSet.map(\.id) == [script.id])
    }

    @Test
    func selectingNilClearsContents() throws {
        let (viewModel, _, scriptStore) = try makeViewModel()
        let script = try scriptStore.create(title: "Member")
        let set = try viewModel.createSet(name: "Set")
        viewModel.select(set)
        try viewModel.addScript(script)
        #expect(!viewModel.scriptsInSelectedSet.isEmpty)
        viewModel.select(nil)
        #expect(viewModel.scriptsInSelectedSet.isEmpty)
        #expect(viewModel.availableScripts.isEmpty)
    }

    // MARK: - Delete

    @Test
    func deleteRemovesSetAndClearsSelectionWhenSelected() throws {
        let (viewModel, _, _) = try makeViewModel()
        let set = try viewModel.createSet(name: "Temp")
        try viewModel.deleteSet(set)
        #expect(viewModel.sets.isEmpty)
        #expect(viewModel.selectedSet == nil)
    }

    // MARK: - Duplicate

    @Test
    func duplicateSetAddsAndSelectsCopy() throws {
        let (viewModel, _, scriptStore) = try makeViewModel()
        let script = try scriptStore.create(title: "Member")
        let original = try viewModel.createSet(name: "Talk")
        viewModel.select(original)
        try viewModel.addScript(script)
        let copy = try viewModel.duplicateSet(original)
        #expect(copy.id != original.id)
        #expect(copy.name == "Talk copy")
        #expect(copy.scriptIDs == [script.id])
        #expect(viewModel.selectedSet?.id == copy.id)
        #expect(viewModel.sets.count == 2)
    }

    // MARK: - Rename

    @Test
    func renameSelectedSetUpdatesName() throws {
        let (viewModel, _, _) = try makeViewModel()
        let set = try viewModel.createSet(name: "Old")
        viewModel.select(set)
        try viewModel.renameSelectedSet(to: "New")
        #expect(set.name == "New")
        #expect(viewModel.sets.first { $0.id == set.id }?.name == "New")
    }

    // MARK: - Active set

    @Test
    func makeActiveSetsActiveSetID() throws {
        let (viewModel, promptSetStore, _) = try makeViewModel()
        let set = try viewModel.createSet(name: "Active")
        viewModel.makeActive(set)
        #expect(promptSetStore.activeSetID == set.id)
        #expect(viewModel.activeSetID == set.id)
    }
}
