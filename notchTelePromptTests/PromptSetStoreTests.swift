//
//  PromptSetStoreTests.swift
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
struct PromptSetStoreTests {
    /// builds a fresh in-memory container and an isolated UserDefaults suite for each test so cases stay isolated.
    private func makeContext() throws -> (container: ModelContainer, defaults: UserDefaults) {
        let container = try ModelContainerFactory.makeInMemory()
        let suiteName = "PromptSetStoreTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw PromptSetStoreTestsError.defaultsUnavailable
        }
        defaults.removePersistentDomain(forName: suiteName)
        return (container, defaults)
    }

    private enum PromptSetStoreTestsError: Error {
        case defaultsUnavailable
    }

    // MARK: - CRUD

    @Test
    func createAddsSet() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Show")
        let all = try store.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.id == set.id)
        #expect(set.name == "Show")
        #expect(set.scriptIDs.isEmpty)
    }

    @Test
    func renameChangesNameAndTimestamp() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Old")
        let originalUpdatedAt = set.updatedAt
        try store.rename(set, to: "New")
        #expect(set.name == "New")
        #expect(set.updatedAt >= originalUpdatedAt)
    }

    @Test
    func deleteRemovesSet() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Temp")
        try store.delete(set)
        #expect(try store.fetchAll().isEmpty)
    }

    @Test
    func deleteClearsActiveSetIDWhenItMatches() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Active")
        store.activeSetID = set.id
        try store.delete(set)
        #expect(store.activeSetID == nil)
    }

    // MARK: - Duplicate

    @Test
    func duplicateCopiesOrderWithCopyName() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let original = try store.create(name: "Talk")
        let a = UUID()
        let b = UUID()
        let c = UUID()
        try store.setOrder([a, b, c], for: original)
        let copy = try store.duplicate(original)
        #expect(copy.name == "Talk copy")
        #expect(copy.scriptIDs == [a, b, c])
        #expect(copy.id != original.id)
        #expect(try store.fetchAll().count == 2)
    }

    @Test
    func duplicateNamingIncrementsOnCollision() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let original = try store.create(name: "Talk")
        let first = try store.duplicate(original)
        let second = try store.duplicate(original)
        #expect(first.name == "Talk copy")
        #expect(second.name == "Talk copy 2")
    }

    // MARK: - Membership

    @Test
    func addScriptAppendsWithoutDuplicates() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Set")
        let a = UUID()
        let b = UUID()
        try store.addScript(a, to: set)
        try store.addScript(b, to: set)
        try store.addScript(a, to: set)
        #expect(set.scriptIDs == [a, b])
    }

    @Test
    func removeScriptDropsID() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Set")
        let a = UUID()
        let b = UUID()
        try store.setOrder([a, b], for: set)
        try store.removeScript(a, from: set)
        #expect(set.scriptIDs == [b])
    }

    // MARK: - Reorder

    @Test
    func moveReordersScriptIDs() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Set")
        let a = UUID()
        let b = UUID()
        let c = UUID()
        try store.setOrder([a, b, c], for: set)
        // move the first element to the end.
        try store.move(in: set, fromOffsets: IndexSet(integer: 0), toOffset: 3)
        #expect(set.scriptIDs == [b, c, a])
    }

    @Test
    func setOrderReplacesOrder() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Set")
        let a = UUID()
        let b = UUID()
        try store.setOrder([a, b], for: set)
        try store.setOrder([b, a], for: set)
        #expect(set.scriptIDs == [b, a])
    }

    // MARK: - Resolved scripts

    @Test
    func resolvedScriptsReturnsInOrderAndSkipsMissing() throws {
        let (container, defaults) = try makeContext()
        let promptSetStore = PromptSetStore(container: container, defaults: defaults)
        let scriptStore = ScriptStore(modelContext: ModelContext(container))
        let first = try scriptStore.create(title: "First")
        let second = try scriptStore.create(title: "Second")
        let set = try promptSetStore.create(name: "Set")
        // include a deleted/unknown id in the middle; it must be skipped while order is preserved.
        let unknown = UUID()
        try promptSetStore.setOrder([second.id, unknown, first.id], for: set)
        let resolved = try promptSetStore.resolvedScripts(for: set, using: scriptStore)
        #expect(resolved.map(\.id) == [second.id, first.id])
    }

    @Test
    func resolvedScriptsSkipsDeletedScript() throws {
        let (container, defaults) = try makeContext()
        let promptSetStore = PromptSetStore(container: container, defaults: defaults)
        let scriptStore = ScriptStore(modelContext: ModelContext(container))
        let keep = try scriptStore.create(title: "Keep")
        let drop = try scriptStore.create(title: "Drop")
        let set = try promptSetStore.create(name: "Set")
        try promptSetStore.setOrder([keep.id, drop.id], for: set)
        try scriptStore.delete(drop)
        let resolved = try promptSetStore.resolvedScripts(for: set, using: scriptStore)
        #expect(resolved.map(\.id) == [keep.id])
    }

    // MARK: - Active set

    @Test
    func activeSetIDPersistsRoundTripAcrossStores() throws {
        let (container, defaults) = try makeContext()
        let id = UUID()
        let firstStore = PromptSetStore(container: container, defaults: defaults)
        firstStore.activeSetID = id
        // a new store reading the same defaults must see the persisted id.
        let secondStore = PromptSetStore(container: container, defaults: defaults)
        #expect(secondStore.activeSetID == id)
    }

    @Test
    func activeSetReturnsPersistedSet() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        let set = try store.create(name: "Active")
        store.activeSetID = set.id
        #expect(try store.activeSet()?.id == set.id)
    }

    @Test
    func activeSetReturnsNilWhenIDNoLongerResolves() throws {
        let (container, defaults) = try makeContext()
        let store = PromptSetStore(container: container, defaults: defaults)
        store.activeSetID = UUID()
        #expect(try store.activeSet() == nil)
    }
}
