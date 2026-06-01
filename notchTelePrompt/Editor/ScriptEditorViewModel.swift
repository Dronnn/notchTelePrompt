//
//  ScriptEditorViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// edits a single script's title and body, tracking stats and debouncing autosave.
@MainActor
@Observable
final class ScriptEditorViewModel {
    var title = "" {
        didSet { handleEdit() }
    }

    var text = "" {
        didSet { handleEdit() }
    }

    var selectedScript: Script? {
        didSet { loadScript(oldValue: oldValue) }
    }

    private(set) var wordCount = 0
    private(set) var charCount = 0
    private(set) var readingTime = "0 min"
    private(set) var isDirty = false
    var errorMessage: String?

    /// the single global prompter font size in points; the editor's +/- control shares this with the
    /// preferences pane and the overlay. reading it in a view body observes the @Observable store, so
    /// the displayed value stays live.
    var fontSize: Double {
        PrompterFontSize.clamp(preferences.prompterDefaults.fontSize)
    }

    /// bound by the +/- control to disable the buttons at the range bounds.
    var canIncreaseFontSize: Bool {
        fontSize < PrompterFontSize.max
    }

    var canDecreaseFontSize: Bool {
        fontSize > PrompterFontSize.min
    }

    private let wpm: Int
    private let store: ScriptStore
    @ObservationIgnored private let preferences: PreferencesStore
    private var autosaveTask: Task<Void, Never>?
    private var isLoading = false

    init(store: ScriptStore, preferences: PreferencesStore = PreferencesStore(), wpm: Int = 150) {
        self.store = store
        self.preferences = preferences
        self.wpm = wpm
        updateStats()
    }

    // MARK: - Selection

    private func loadScript(oldValue: Script?) {
        // flush any pending edits to the previously selected script before switching, to avoid data loss.
        if let oldValue, isDirty {
            saveScript(oldValue, title: title, text: text)
        }
        autosaveTask?.cancel()
        autosaveTask = nil

        isLoading = true
        title = selectedScript?.title ?? ""
        text = selectedScript?.text ?? ""
        updateStats()
        isDirty = false
        isLoading = false
    }

    // MARK: - Editing

    private func handleEdit() {
        guard !isLoading else { return }
        updateStats()
        isDirty = true
        scheduleAutosave()
    }

    private func updateStats() {
        wordCount = ReadingTimeHelper.wordCount(in: text)
        charCount = ReadingTimeHelper.characterCount(in: text)
        readingTime = ReadingTimeHelper.readingTime(wordCount: wordCount, wpm: wpm)
    }

    // MARK: - Saving

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled, let self else { return }
            save()
        }
    }

    func save() {
        guard let selectedScript else { return }
        saveScript(selectedScript, title: title, text: text)
    }

    func saveImmediately() {
        autosaveTask?.cancel()
        autosaveTask = nil
        save()
    }

    /// drops any unsaved edits without writing them, so a pending autosave/dirty flush
    /// cannot overwrite content that another path is about to set on the same script.
    func cancelPendingEdits() {
        autosaveTask?.cancel()
        autosaveTask = nil
        isDirty = false
    }

    private func saveScript(_ script: Script, title: String, text: String) {
        do {
            try store.update(script, title: title, text: text)
            isDirty = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Font size

    func increaseFontSize() {
        applyFontSize(PrompterFontSize.incremented(fontSize))
    }

    func decreaseFontSize() {
        applyFontSize(PrompterFontSize.decremented(fontSize))
    }

    /// clamps and writes through the single global font default; persisting keeps the overlay in sync.
    private func applyFontSize(_ newValue: Double) {
        let clamped = PrompterFontSize.clamp(newValue)
        guard clamped != preferences.prompterDefaults.fontSize else {
            return
        }
        preferences.prompterDefaults.fontSize = clamped
    }
}
