//
//  PromptSetStore.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import SwiftData

/// owns the SwiftData model context and exposes the prompt-set library operations.
/// main-actor isolated because it drives the UI layer and the context is not Sendable.
@MainActor
@Observable
final class PromptSetStore {
    static let activeSetIDKey = "activePromptSetID"

    private let modelContext: ModelContext
    private let defaults: UserDefaults

    init(modelContext: ModelContext, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.defaults = defaults
    }

    convenience init(container: ModelContainer, defaults: UserDefaults = .standard) {
        self.init(modelContext: ModelContext(container), defaults: defaults)
    }

    // MARK: - Create

    @discardableResult
    func create(name: String = "") throws -> PromptSet {
        let set = PromptSet(name: name)
        modelContext.insert(set)
        try modelContext.save()
        return set
    }

    // MARK: - Read

    /// all prompt sets, most recently updated first.
    func fetchAll() throws -> [PromptSet] {
        try modelContext.fetch(
            FetchDescriptor<PromptSet>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        )
    }

    /// resolves the set's scriptIDs to scripts in order, skipping ids that no longer match a script.
    func resolvedScripts(for set: PromptSet, using scriptStore: ScriptStore) throws -> [Script] {
        try set.scriptIDs.compactMap { try scriptStore.script(withID: $0) }
    }

    // MARK: - Update

    func rename(_ set: PromptSet, to name: String) throws {
        set.name = name
        set.updatedAt = .now
        try modelContext.save()
    }

    /// appends a script id if the set does not already contain it; keeps the set free of duplicates.
    func addScript(_ scriptID: UUID, to set: PromptSet) throws {
        guard !set.scriptIDs.contains(scriptID) else {
            return
        }
        set.scriptIDs.append(scriptID)
        set.updatedAt = .now
        try modelContext.save()
    }

    func removeScript(_ scriptID: UUID, from set: PromptSet) throws {
        guard set.scriptIDs.contains(scriptID) else {
            return
        }
        set.scriptIDs.removeAll { $0 == scriptID }
        set.updatedAt = .now
        try modelContext.save()
    }

    /// reorders the set's scriptIDs, matching the SwiftUI onMove(fromOffsets:toOffset:) semantics.
    /// reimplemented here so the store stays free of SwiftUI.
    func move(in set: PromptSet, fromOffsets: IndexSet, toOffset: Int) throws {
        var ids = set.scriptIDs
        let moving = fromOffsets.sorted().map { ids[$0] }
        for index in fromOffsets.sorted(by: >) {
            ids.remove(at: index)
        }
        let insertionIndex = toOffset - fromOffsets.filter { $0 < toOffset }.count
        ids.insert(contentsOf: moving, at: insertionIndex)
        set.scriptIDs = ids
        set.updatedAt = .now
        try modelContext.save()
    }

    /// replaces the set's order with the given ids; use for explicit drag-reorder results.
    func setOrder(_ ids: [UUID], for set: PromptSet) throws {
        set.scriptIDs = ids
        set.updatedAt = .now
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(_ set: PromptSet) throws {
        if activeSetID == set.id {
            activeSetID = nil
        }
        modelContext.delete(set)
        try modelContext.save()
    }

    // MARK: - Duplicate

    @discardableResult
    func duplicate(_ set: PromptSet) throws -> PromptSet {
        let existingNames = try fetchAll().map(\.name)
        let copy = PromptSet(
            name: ScriptStore.copyTitle(for: set.name, existingTitles: existingNames),
            scriptIDs: set.scriptIDs
        )
        modelContext.insert(copy)
        try modelContext.save()
        return copy
    }

    // MARK: - Active set

    /// the last active set's id, persisted in UserDefaults as a string. nil when none is active.
    var activeSetID: UUID? {
        get {
            guard let raw = defaults.string(forKey: Self.activeSetIDKey) else {
                return nil
            }
            return UUID(uuidString: raw)
        }
        set {
            if let newValue {
                defaults.set(newValue.uuidString, forKey: Self.activeSetIDKey)
            } else {
                defaults.removeObject(forKey: Self.activeSetIDKey)
            }
        }
    }

    /// the currently active set, or nil if none is active or the active id no longer resolves.
    func activeSet() throws -> PromptSet? {
        guard let id = activeSetID else {
            return nil
        }
        var descriptor = FetchDescriptor<PromptSet>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
