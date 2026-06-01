//
//  ScriptStore.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import SwiftData

/// owns the SwiftData model context and exposes the script library operations.
/// main-actor isolated because it drives the UI layer and the context is not Sendable.
@MainActor
@Observable
final class ScriptStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    convenience init(container: ModelContainer) {
        self.init(modelContext: ModelContext(container))
    }

    // MARK: - Create

    @discardableResult
    func create(title: String = "", text: String = "") throws -> Script {
        let script = Script(title: title, text: text)
        modelContext.insert(script)
        try modelContext.save()
        return script
    }

    // MARK: - Read

    func fetchAll(sortedBy order: ScriptSortOrder = .updatedDescending) throws -> [Script] {
        try modelContext.fetch(FetchDescriptor<Script>(sortBy: order.sortDescriptors))
    }

    /// most recently used scripts first; scripts never used (nil lastUsedAt) are excluded.
    func recent(limit: Int = 10) throws -> [Script] {
        var descriptor = FetchDescriptor<Script>(
            predicate: #Predicate { $0.lastUsedAt != nil },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    /// the single most recently used script, or nil if none has been used; convenience for the prompter entry point.
    var mostRecentScript: Script? {
        (try? recent(limit: 1))?.first
    }

    /// fetches a single script by its id, or nil if no script with that id exists.
    func script(withID id: UUID) throws -> Script? {
        var descriptor = FetchDescriptor<Script>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// filters by query using localized, case- and diacritic-insensitive matching on title and text.
    func search(_ query: String, sortedBy order: ScriptSortOrder = .updatedDescending) throws -> [Script] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return try fetchAll(sortedBy: order)
        }
        // localizedStandardContains is not expressible in #Predicate, so filter in memory after fetching.
        return try fetchAll(sortedBy: order).filter {
            $0.title.localizedStandardContains(trimmed) || $0.text.localizedStandardContains(trimmed)
        }
    }

    // MARK: - Update

    func update(_ script: Script, title: String? = nil, text: String? = nil) throws {
        if let title {
            script.title = title
        }
        if let text {
            script.text = text
        }
        script.updatedAt = .now
        try modelContext.save()
    }

    func markUsed(_ script: Script, at date: Date = .now) throws {
        script.lastUsedAt = date
        try modelContext.save()
    }

    func toggleFavorite(_ script: Script) throws {
        script.isFavorite.toggle()
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(_ script: Script) throws {
        modelContext.delete(script)
        try modelContext.save()
    }

    /// removes every script in one save; used by the privacy pane's clear-local-data action.
    func deleteAll() throws {
        try modelContext.delete(model: Script.self)
        try modelContext.save()
    }

    // MARK: - Duplicate

    @discardableResult
    func duplicate(_ script: Script) throws -> Script {
        let existingTitles = try fetchAll().map(\.title)
        let copy = Script(
            title: Self.copyTitle(for: script.title, existingTitles: existingTitles),
            text: script.text,
            isFavorite: false,
            settingsBlob: script.settingsBlob
        )
        modelContext.insert(copy)
        try modelContext.save()
        return copy
    }

    /// builds a non-colliding "copy" title: "x copy", then "x copy 2", "x copy 3", ...
    static func copyTitle(for original: String, existingTitles: [String]) -> String {
        let base = original.isEmpty ? "Untitled" : original
        let firstCandidate = "\(base) copy"
        guard existingTitles.contains(firstCandidate) else {
            return firstCandidate
        }
        var index = 2
        while existingTitles.contains("\(base) copy \(index)") {
            index += 1
        }
        return "\(base) copy \(index)"
    }
}
