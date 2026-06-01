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

    /// the per-script prompter font size in points, mirrored from the selected script's settings;
    /// the view binds to this rather than reading the @Model directly.
    private(set) var fontSize = PrompterFontSize.default

    /// bound by the +/- control to disable the buttons at the range bounds.
    var canIncreaseFontSize: Bool {
        fontSize < PrompterFontSize.max
    }

    var canDecreaseFontSize: Bool {
        fontSize > PrompterFontSize.min
    }

    private let wpm: Int
    private let store: ScriptStore
    private var autosaveTask: Task<Void, Never>?
    private var isLoading = false
    @ObservationIgnored private var fontSizeObserver: NotificationObserverToken?

    init(store: ScriptStore, wpm: Int = 150) {
        self.store = store
        self.wpm = wpm
        updateStats()
        observeFontSizeChanges()
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
        reloadFontSize()
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

    /// clamps, mirrors, persists through the store and broadcasts so the overlay stays in sync.
    private func applyFontSize(_ newValue: Double) {
        guard let selectedScript else {
            return
        }
        let clamped = PrompterFontSize.clamp(newValue)
        guard clamped != fontSize else {
            return
        }
        fontSize = clamped
        do {
            try store.setFontSize(clamped, on: selectedScript)
            NotificationCenter.default.post(
                name: .scriptFontSizeDidChange,
                object: nil,
                userInfo: [ScriptFontSizeChange.scriptIDKey: selectedScript.id]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// refreshes the mirror from the selected script's stored settings, defaulting when none exist.
    private func reloadFontSize() {
        fontSize = PrompterFontSize.clamp(selectedScript?.settingsBlob?.fontSize ?? PrompterFontSize.default)
    }

    /// re-reads the size when another surface (the overlay) changes it for the selected script.
    private func observeFontSizeChanges() {
        fontSizeObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .scriptFontSizeDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let changedID = notification.userInfo?[ScriptFontSizeChange.scriptIDKey] as? UUID
            Task { @MainActor in
                guard let self, let changedID, self.selectedScript?.id == changedID else {
                    return
                }
                self.reloadFontSize()
            }
        })
    }
}
