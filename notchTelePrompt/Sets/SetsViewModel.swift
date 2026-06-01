//
//  SetsViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// drives the main-window sets section: the list of sets, the selected set's ordered prompts,
/// the library scripts still available to add, and every set mutation.
/// mirrors @Model values into plain arrays so the view layer never touches SwiftData models directly.
@MainActor
@Observable
final class SetsViewModel {
    private(set) var sets: [PromptSet] = []
    private(set) var scriptsInSelectedSet: [Script] = []
    private(set) var availableScripts: [Script] = []

    var selectedSet: PromptSet? {
        didSet { refreshSelectedSetContents() }
    }

    /// the active set's id, mirrored from the store so the sidebar can mark the active row.
    private(set) var activeSetID: UUID?

    var errorMessage: String?

    private let promptSetStore: PromptSetStore
    private let scriptStore: ScriptStore
    @ObservationIgnored private var changeObserver: NotificationObserverToken?

    init(promptSetStore: PromptSetStore, scriptStore: ScriptStore) {
        self.promptSetStore = promptSetStore
        self.scriptStore = scriptStore
        activeSetID = promptSetStore.activeSetID
        refreshSets()
        observeSetChanges()
    }

    // MARK: - Loading

    func refreshSets() {
        do {
            sets = try promptSetStore.fetchAll()
            activeSetID = promptSetStore.activeSetID
            // keep the selection pointing at a still-existing set, or drop it.
            if let selectedSet, !sets.contains(where: { $0.id == selectedSet.id }) {
                self.selectedSet = nil
            } else {
                refreshSelectedSetContents()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// recomputes the resolved prompts in the selected set and the library scripts not yet in it.
    private func refreshSelectedSetContents() {
        guard let selectedSet else {
            scriptsInSelectedSet = []
            availableScripts = []
            return
        }
        do {
            let resolved = try promptSetStore.resolvedScripts(for: selectedSet, using: scriptStore)
            scriptsInSelectedSet = resolved
            let memberIDs = Set(selectedSet.scriptIDs)
            availableScripts = try scriptStore.fetchAll().filter { !memberIDs.contains($0.id) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Selection

    func select(_ set: PromptSet?) {
        selectedSet = set
    }

    // MARK: - Set mutations

    @discardableResult
    func createSet(name: String = "") throws -> PromptSet {
        let set = try promptSetStore.create(name: name)
        refreshSets()
        selectedSet = set
        return set
    }

    func renameSelectedSet(to name: String) throws {
        guard let selectedSet else {
            return
        }
        try promptSetStore.rename(selectedSet, to: name)
        refreshSets()
    }

    func deleteSet(_ set: PromptSet) throws {
        if selectedSet?.id == set.id {
            selectedSet = nil
        }
        try promptSetStore.delete(set)
        refreshSets()
    }

    @discardableResult
    func duplicateSet(_ set: PromptSet) throws -> PromptSet {
        let copy = try promptSetStore.duplicate(set)
        refreshSets()
        selectedSet = copy
        return copy
    }

    // MARK: - Membership

    func addScript(_ script: Script) throws {
        guard let selectedSet else {
            return
        }
        try promptSetStore.addScript(script.id, to: selectedSet)
        refreshSelectedSetContents()
        postChange(for: selectedSet)
    }

    func removeScript(_ script: Script) throws {
        guard let selectedSet else {
            return
        }
        try promptSetStore.removeScript(script.id, from: selectedSet)
        refreshSelectedSetContents()
        postChange(for: selectedSet)
    }

    func move(fromOffsets: IndexSet, toOffset: Int) throws {
        guard let selectedSet else {
            return
        }
        try promptSetStore.move(in: selectedSet, fromOffsets: fromOffsets, toOffset: toOffset)
        refreshSelectedSetContents()
        postChange(for: selectedSet)
    }

    // MARK: - Active set

    func makeActive(_ set: PromptSet) {
        promptSetStore.activeSetID = set.id
        activeSetID = set.id
        postChange(for: set)
    }

    // MARK: - Change broadcast

    /// notifies the navigator (and any other surface) that a set's contents changed.
    private func postChange(for set: PromptSet) {
        NotificationCenter.default.post(
            name: .promptSetDidChange,
            object: nil,
            userInfo: [PromptSetChange.setIDKey: set.id]
        )
    }

    /// refreshes when a set is mutated elsewhere (e.g. reordered from the floating navigator).
    private func observeSetChanges() {
        changeObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .promptSetDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshSets()
            }
        })
    }
}
