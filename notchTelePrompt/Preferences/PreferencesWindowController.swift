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
final class PreferencesWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let preferencesStore: PreferencesStore
    private let scriptStore: ScriptStore
    private let tipStore: TipStore

    /// invoked from the privacy pane; set by the app delegate after construction. the window is built
    /// lazily on first show(), so these are captured by then.
    var onExportAllScripts: (() -> Void)?
    var onClearLocalData: (() -> Void)?

    // MARK: - Lifecycle

    init(preferencesStore: PreferencesStore, scriptStore: ScriptStore, tipStore: TipStore) {
        self.preferencesStore = preferencesStore
        self.scriptStore = scriptStore
        self.tipStore = tipStore
        super.init()
    }

    // MARK: - Presentation

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    func show() {
        let existingWindow = window ?? makeWindow()
        window = existingWindow
        AppWindowPlacement.place(existingWindow)
        existingWindow.level = AppWindowPlacement.activeWindowLevel
        // bring the app forward so the recorder can become key and capture keys.
        NSApp.activate(ignoringOtherApps: true)
        existingWindow.makeKeyAndOrderFront(nil)
    }

    /// flips the preferences window between shown and hidden; used by the prompter's preferences toggle.
    func toggle() {
        if isVisible {
            window?.orderOut(nil)
        } else {
            show()
        }
    }

    func windowDidBecomeKey(_: Notification) {
        window?.level = AppWindowPlacement.activeWindowLevel
    }

    func windowDidResignKey(_: Notification) {
        window?.level = .normal
    }

    // MARK: - Window

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "Preferences")
        window.identifier = AppWindowPlacement.preferencesIdentifier
        window.isMovableByWindowBackground = true
        window.contentMinSize = NSSize(width: 460, height: 360)
        window.delegate = self
        // the controller outlives a closed window, so reopening must not use a deallocated instance.
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: PreferencesView(
                preferencesStore: preferencesStore,
                scriptStore: scriptStore,
                tipStore: tipStore,
                onExportAllScripts: { [weak self] in self?.onExportAllScripts?() },
                onClearLocalData: { [weak self] in self?.onClearLocalData?() }
            )
        )
        window.center()
        return window
    }
}
