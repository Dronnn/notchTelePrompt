//
//  ScriptStoreTests.swift
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
struct ScriptStoreTests {
    /// builds a fresh in-memory store for each test so cases stay isolated.
    private func makeStore() throws -> ScriptStore {
        let container = try ModelContainerFactory.makeInMemory()
        return ScriptStore(container: container)
    }

    // MARK: - CRUD

    @Test
    func createAddsScript() throws {
        let store = try makeStore()
        let script = try store.create(title: "Intro", text: "hello")
        let all = try store.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.id == script.id)
        #expect(script.title == "Intro")
        #expect(script.text == "hello")
    }

    @Test
    func updateChangesFieldsAndTimestamp() throws {
        let store = try makeStore()
        let script = try store.create(title: "Old", text: "old body")
        let originalUpdatedAt = script.updatedAt
        try store.update(script, title: "New", text: "new body")
        #expect(script.title == "New")
        #expect(script.text == "new body")
        #expect(script.updatedAt >= originalUpdatedAt)
    }

    @Test
    func deleteRemovesScript() throws {
        let store = try makeStore()
        let script = try store.create(title: "Temp")
        try store.delete(script)
        #expect(try store.fetchAll().isEmpty)
    }

    // MARK: - Duplicate

    @Test
    func duplicateCreatesCopyWithCopyTitle() throws {
        let store = try makeStore()
        let original = try store.create(title: "Talk", text: "body")
        original.isFavorite = true
        let copy = try store.duplicate(original)
        #expect(copy.title == "Talk copy")
        #expect(copy.text == "body")
        #expect(copy.isFavorite == false)
        #expect(copy.id != original.id)
        #expect(try store.fetchAll().count == 2)
    }

    @Test
    func duplicateNamingIncrementsOnCollision() throws {
        let store = try makeStore()
        let original = try store.create(title: "Talk")
        let first = try store.duplicate(original)
        let second = try store.duplicate(original)
        #expect(first.title == "Talk copy")
        #expect(second.title == "Talk copy 2")
    }

    @Test
    func copyTitleHandlesEmptyTitle() {
        #expect(ScriptStore.copyTitle(for: "", existingTitles: []) == "Untitled copy")
    }

    // MARK: - Search

    @Test
    func searchMatchesTitleAndBodyCaseInsensitively() throws {
        let store = try makeStore()
        try store.create(title: "Morning Show", text: "weather report")
        try store.create(title: "Evening", text: "the MORNING after")
        try store.create(title: "Other", text: "nothing")
        let results = try store.search("morning")
        #expect(results.count == 2)
    }

    @Test
    func searchEmptyQueryReturnsAll() throws {
        let store = try makeStore()
        try store.create(title: "A")
        try store.create(title: "B")
        #expect(try store.search("   ").count == 2)
    }

    // MARK: - Sort

    @Test
    func fetchAllSortsByUpdatedDescending() throws {
        let store = try makeStore()
        let older = try store.create(title: "Older")
        let newer = try store.create(title: "Newer")
        try store.update(older, text: "touched")
        let results = try store.fetchAll(sortedBy: .updatedDescending)
        #expect(results.first?.id == older.id)
        #expect(results.last?.id == newer.id)
    }

    @Test
    func fetchAllSortsByTitleAscending() throws {
        let store = try makeStore()
        try store.create(title: "Charlie")
        try store.create(title: "alpha")
        try store.create(title: "Bravo")
        let titles = try store.fetchAll(sortedBy: .titleAscending).map(\.title)
        #expect(titles == ["alpha", "Bravo", "Charlie"])
    }

    // MARK: - Font size

    @Test
    func setFontSizeCreatesBlobWhenAbsentAndClamps() throws {
        let store = try makeStore()
        let script = try store.create(title: "Sized")
        #expect(script.settingsBlob == nil)
        try store.setFontSize(40, on: script)
        #expect(script.settingsBlob?.fontSize == 40)
        // out-of-range values are clamped to the allowed maximum.
        try store.setFontSize(PrompterFontSize.max + 100, on: script)
        #expect(script.settingsBlob?.fontSize == PrompterFontSize.max)
    }

    @Test
    func setFontSizeDoesNotTouchUpdatedAt() throws {
        let store = try makeStore()
        let script = try store.create(title: "Sized")
        let originalUpdatedAt = script.updatedAt
        try store.setFontSize(40, on: script)
        #expect(script.updatedAt == originalUpdatedAt)
    }

    // MARK: - Favorite

    @Test
    func toggleFavoriteFlipsState() throws {
        let store = try makeStore()
        let script = try store.create(title: "Fav")
        #expect(script.isFavorite == false)
        try store.toggleFavorite(script)
        #expect(script.isFavorite == true)
        try store.toggleFavorite(script)
        #expect(script.isFavorite == false)
    }

    // MARK: - Recent

    @Test
    func recentReturnsUsedScriptsMostRecentFirst() throws {
        let store = try makeStore()
        let first = try store.create(title: "First")
        let second = try store.create(title: "Second")
        let neverUsed = try store.create(title: "NeverUsed")
        let base = Date(timeIntervalSince1970: 1_000_000)
        try store.markUsed(first, at: base)
        try store.markUsed(second, at: base.addingTimeInterval(60))
        let recent = try store.recent()
        #expect(recent.map(\.id) == [second.id, first.id])
        #expect(!recent.contains { $0.id == neverUsed.id })
    }

    @Test
    func recentHonorsLimit() throws {
        let store = try makeStore()
        let base = Date(timeIntervalSince1970: 1_000_000)
        for index in 0 ..< 5 {
            let script = try store.create(title: "S\(index)")
            try store.markUsed(script, at: base.addingTimeInterval(Double(index)))
        }
        #expect(try store.recent(limit: 3).count == 3)
    }
}
