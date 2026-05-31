//
//  ScriptEditorViewModelTests.swift
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
struct ScriptEditorViewModelTests {
    /// builds a fresh in-memory store for each test so cases stay isolated.
    private func makeStore() throws -> ScriptStore {
        let container = try ModelContainerFactory.makeInMemory()
        return ScriptStore(container: container)
    }

    // MARK: - Selection

    @Test
    func selectingScriptPopulatesTitleAndText() throws {
        let store = try makeStore()
        let script = try store.create(title: "Intro", text: "hello world")
        let viewModel = ScriptEditorViewModel(store: store)
        viewModel.selectedScript = script
        #expect(viewModel.title == "Intro")
        #expect(viewModel.text == "hello world")
        #expect(viewModel.isDirty == false)
    }

    @Test
    func selectingNilResetsEditor() throws {
        let store = try makeStore()
        let script = try store.create(title: "Intro", text: "hello")
        let viewModel = ScriptEditorViewModel(store: store)
        viewModel.selectedScript = script
        viewModel.selectedScript = nil
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.text.isEmpty)
        #expect(viewModel.isDirty == false)
    }

    // MARK: - Dirty tracking

    @Test
    func changingTitleMarksDirty() throws {
        let store = try makeStore()
        let script = try store.create(title: "Intro", text: "hello")
        let viewModel = ScriptEditorViewModel(store: store)
        viewModel.selectedScript = script
        #expect(viewModel.isDirty == false)
        viewModel.title = "Changed"
        #expect(viewModel.isDirty == true)
    }

    @Test
    func changingTextMarksDirty() throws {
        let store = try makeStore()
        let script = try store.create(title: "Intro", text: "hello")
        let viewModel = ScriptEditorViewModel(store: store)
        viewModel.selectedScript = script
        viewModel.text = "new body"
        #expect(viewModel.isDirty == true)
    }

    // MARK: - Stats

    @Test
    func statsAndReadingTimeUpdateOnTextChange() throws {
        let store = try makeStore()
        let viewModel = ScriptEditorViewModel(store: store)
        let script = try store.create()
        viewModel.selectedScript = script
        viewModel.text = "one two three"
        #expect(viewModel.wordCount == 3)
        #expect(viewModel.charCount == 13)
        #expect(viewModel.readingTime == ReadingTimeHelper.readingTime(wordCount: 3))
    }

    // MARK: - Saving

    @Test
    func saveImmediatelyPersistsAndClearsDirty() throws {
        let store = try makeStore()
        let script = try store.create(title: "Old", text: "old body")
        let viewModel = ScriptEditorViewModel(store: store)
        viewModel.selectedScript = script
        viewModel.title = "New"
        viewModel.text = "new body"
        #expect(viewModel.isDirty == true)
        viewModel.saveImmediately()
        #expect(viewModel.isDirty == false)
        #expect(script.title == "New")
        #expect(script.text == "new body")
        let reloaded = try store.fetchAll().first { $0.id == script.id }
        #expect(reloaded?.title == "New")
        #expect(reloaded?.text == "new body")
    }

    @Test
    func switchingScriptsFlushesDirtyPreviousEdits() throws {
        let store = try makeStore()
        let first = try store.create(title: "First", text: "first body")
        let second = try store.create(title: "Second", text: "second body")
        let viewModel = ScriptEditorViewModel(store: store)
        viewModel.selectedScript = first
        viewModel.title = "edited first title"
        viewModel.text = "edited first body"
        #expect(viewModel.isDirty == true)
        // switching without an explicit save must not lose the edit.
        viewModel.selectedScript = second
        #expect(first.title == "edited first title")
        #expect(first.text == "edited first body")
        let reloadedFirst = try store.fetchAll().first { $0.id == first.id }
        #expect(reloadedFirst?.title == "edited first title")
        #expect(reloadedFirst?.text == "edited first body")
        #expect(viewModel.title == "Second")
        #expect(viewModel.text == "second body")
        #expect(viewModel.isDirty == false)
    }

    @Test
    func savingWithNoSelectionIsSafeNoOp() throws {
        let store = try makeStore()
        let script = try store.create(title: "Untouched", text: "untouched body")
        let viewModel = ScriptEditorViewModel(store: store)
        // no script selected; saving must not crash or mutate anything.
        viewModel.saveImmediately()
        #expect(viewModel.selectedScript == nil)
        #expect(viewModel.isDirty == false)
        #expect(viewModel.errorMessage == nil)
        let reloaded = try store.fetchAll().first { $0.id == script.id }
        #expect(reloaded?.title == "Untouched")
        #expect(reloaded?.text == "untouched body")
    }

    @Test
    func emptyTitleIsAllowed() throws {
        let store = try makeStore()
        let script = try store.create(title: "Has title", text: "body")
        let viewModel = ScriptEditorViewModel(store: store)
        viewModel.selectedScript = script
        viewModel.title = ""
        viewModel.saveImmediately()
        #expect(script.title.isEmpty)
        #expect(viewModel.isDirty == false)
    }
}
