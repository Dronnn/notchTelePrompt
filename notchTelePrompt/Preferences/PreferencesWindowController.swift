//
//  PreferencesWindowController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// owns one reusable preferences window for the app's lifetime, lazily created on first show.
/// a normal titled window (not a panel) so the shortcut recorders can become key/first-responder
/// and capture keystrokes while recording.
@MainActor
final class PreferencesWindowController: NSObject {
    private var window: NSWindow?
    private let preferencesStore: PreferencesStore
    private let scriptStore: ScriptStore

    /// invoked from the privacy pane; set by the app delegate after construction. the window is built
    /// lazily on first show(), so these are captured by then.
    var onExportAllScripts: (() -> Void)?
    var onClearLocalData: (() -> Void)?

    // MARK: - Lifecycle

    init(preferencesStore: PreferencesStore, scriptStore: ScriptStore) {
        self.preferencesStore = preferencesStore
        self.scriptStore = scriptStore
        super.init()
    }

    // MARK: - Presentation

    func show() {
        let existingWindow = window ?? makeWindow()
        window = existingWindow
        // bring the app forward so the recorder can become key and capture keys.
        NSApp.activate(ignoringOtherApps: true)
        existingWindow.makeKeyAndOrderFront(nil)
    }

    // MARK: - Window

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "Preferences")
        // the controller outlives a closed window, so reopening must not use a deallocated instance.
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: PreferencesView(
                preferencesStore: preferencesStore,
                scriptStore: scriptStore,
                onExportAllScripts: { [weak self] in self?.onExportAllScripts?() },
                onClearLocalData: { [weak self] in self?.onClearLocalData?() }
            )
        )
        window.center()
        return window
    }
}
