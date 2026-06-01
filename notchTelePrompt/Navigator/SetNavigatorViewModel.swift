//
//  SetNavigatorViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// holds the state the floating set navigator renders: the active set, its resolved scripts in order,
/// and which script is currently highlighted. selecting a row (or stepping next/previous) reports the
/// chosen script back through onSelectScript so the controller can drive the prompter.
@MainActor
@Observable
final class SetNavigatorViewModel {
    /// the active set being navigated, or nil when none is active.
    private(set) var activeSet: PromptSet?

    /// the active set's scripts resolved in order, with missing ids already filtered out by the store.
    private(set) var scripts: [Script] = []

    /// the highlighted script's id, or nil when nothing has been picked yet.
    private(set) var selectedScriptID: UUID?

    /// reports the chosen script so the controller can show it in the prompter; wired by the controller / AppDelegate.
    var onSelectScript: ((Script) -> Void)?

    @ObservationIgnored private let promptSetStore: PromptSetStore
    @ObservationIgnored private let scriptStore: ScriptStore
    @ObservationIgnored private var setChangeObserver: NotificationObserverToken?

    init(promptSetStore: PromptSetStore, scriptStore: ScriptStore) {
        self.promptSetStore = promptSetStore
        self.scriptStore = scriptStore
        observeSetChanges()
    }

    // MARK: - Loading

    /// loads the active set and its resolved scripts; clears the selection if it no longer resolves.
    func refresh() {
        let set = try? promptSetStore.activeSet()
        activeSet = set
        if let set {
            scripts = (try? promptSetStore.resolvedScripts(for: set, using: scriptStore)) ?? []
        } else {
            scripts = []
        }
        // drop a highlight that points at a script no longer in the set.
        if let selectedScriptID, !scripts.contains(where: { $0.id == selectedScriptID }) {
            self.selectedScriptID = nil
        }
    }

    /// entry point the controller calls when the active set changes; reloads from the store.
    func setActiveSet(id _: UUID?) {
        refresh()
    }

    // MARK: - Selection

    /// highlights the script and reports it for display in the prompter.
    func select(_ script: Script) {
        selectedScriptID = script.id
        onSelectScript?(script)
    }

    var canGoNext: Bool {
        guard let index = NavigatorSelection.nextIndex(after: selectedIndex, count: scripts.count) else {
            return false
        }
        return index != selectedIndex
    }

    var canGoPrevious: Bool {
        guard let index = NavigatorSelection.previousIndex(before: selectedIndex, count: scripts.count) else {
            return false
        }
        return index != selectedIndex
    }

    /// moves the highlight to the next script (clamped at the end) and reports it.
    func next() {
        guard
            let index = NavigatorSelection.nextIndex(after: selectedIndex, count: scripts.count),
            scripts.indices.contains(index)
        else {
            return
        }
        select(scripts[index])
    }

    /// moves the highlight to the previous script (clamped at the start) and reports it.
    func previous() {
        guard
            let index = NavigatorSelection.previousIndex(before: selectedIndex, count: scripts.count),
            scripts.indices.contains(index)
        else {
            return
        }
        select(scripts[index])
    }

    // MARK: - Reordering

    /// reorders the active set's scripts through the store, refreshes, and broadcasts the change so
    /// the main-window sets editor stays in sync.
    func move(fromOffsets: IndexSet, toOffset: Int) {
        guard let set = activeSet else {
            return
        }
        try? promptSetStore.move(in: set, fromOffsets: fromOffsets, toOffset: toOffset)
        refresh()
        NotificationCenter.default.post(
            name: .promptSetDidChange,
            object: nil,
            userInfo: [PromptSetChange.setIDKey: set.id]
        )
    }

    // MARK: - Helpers

    /// the index of the highlighted script in the current list, or nil when nothing is selected.
    private var selectedIndex: Int? {
        guard let selectedScriptID else {
            return nil
        }
        return scripts.firstIndex { $0.id == selectedScriptID }
    }

    /// re-reads the set when its contents or order change elsewhere (e.g. the main-window sets editor),
    /// but only when the change concerns the set we are showing.
    private func observeSetChanges() {
        setChangeObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .promptSetDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                // the navigator always shows whatever set is active, so refresh on any set change —
                // including the active set being switched to a different one in the main window.
                self?.refresh()
            }
        })
    }
}
