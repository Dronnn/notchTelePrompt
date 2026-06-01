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

    // MARK: - Font size

    /// builds an editor view model wired to an isolated PreferencesStore so font-size cases (which now
    /// read/write the single global default) stay isolated from each other and from .standard defaults.
    private func makeViewModel(store: ScriptStore) throws -> (ScriptEditorViewModel, PreferencesStore) {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let preferences = PreferencesStore(defaults: defaults)
        return (ScriptEditorViewModel(store: store, preferences: preferences), preferences)
    }

    @Test
    func fontSizeReadsGlobalDefault() throws {
        let store = try makeStore()
        let script = try store.create(title: "Plain")
        let (viewModel, _) = try makeViewModel(store: store)
        viewModel.selectedScript = script
        #expect(viewModel.fontSize == PrompterFontSize.default)
    }

    @Test
    func increaseAndDecreaseFontSizeWritesGlobalDefault() throws {
        let store = try makeStore()
        let script = try store.create(title: "Sized")
        let (viewModel, preferences) = try makeViewModel(store: store)
        viewModel.selectedScript = script
        viewModel.increaseFontSize()
        #expect(viewModel.fontSize == PrompterFontSize.default + PrompterFontSize.step)
        #expect(preferences.prompterDefaults.fontSize == PrompterFontSize.default + PrompterFontSize.step)
        viewModel.decreaseFontSize()
        #expect(viewModel.fontSize == PrompterFontSize.default)
        #expect(preferences.prompterDefaults.fontSize == PrompterFontSize.default)
    }

    @Test
    func fontSizeMirrorReadsGlobalDefault() throws {
        let store = try makeStore()
        let script = try store.create(title: "Sized")
        let (viewModel, preferences) = try makeViewModel(store: store)
        preferences.prompterDefaults.fontSize = 60
        viewModel.selectedScript = script
        #expect(viewModel.fontSize == 60)
    }

    @Test
    func fontSizeBoundsDisableFlags() throws {
        let store = try makeStore()
        let script = try store.create(title: "Sized")
        let (viewModel, preferences) = try makeViewModel(store: store)
        viewModel.selectedScript = script
        preferences.prompterDefaults.fontSize = PrompterFontSize.max
        #expect(viewModel.canIncreaseFontSize == false)
        #expect(viewModel.canDecreaseFontSize == true)
        preferences.prompterDefaults.fontSize = PrompterFontSize.min
        #expect(viewModel.canDecreaseFontSize == false)
        #expect(viewModel.canIncreaseFontSize == true)
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
