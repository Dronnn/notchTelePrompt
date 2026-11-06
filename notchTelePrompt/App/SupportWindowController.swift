//
//  SupportWindowController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

@MainActor
final class SupportWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let store: TipStore

    init(store: TipStore, preferences: PreferencesStore) {
        self.store = store
        window = NSWindow(contentViewController: NSHostingController(
            rootView: AppLanguageRoot(preferencesStore: preferences) {
                SupportView(store: store)
            }
        ))
        super.init()
        window.title = AppLocalization.string("Support NotchPrompter")
        window.identifier = AppWindowPlacement.supportIdentifier
        window.styleMask = [.titled, .closable, .resizable]
        window.isMovableByWindowBackground = true
        window.setContentSize(NSSize(width: 520, height: 620))
        window.contentMinSize = NSSize(width: 400, height: 400)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appLanguageDidChange),
            name: .appLanguageDidChange,
            object: nil
        )
    }

    @objc
    private func appLanguageDidChange() {
        window.title = AppLocalization.string("Support NotchPrompter")
    }

    func show() {
        AppWindowPlacement.place(window)
        window.level = AppWindowPlacement.activeWindowLevel
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowDidBecomeKey(_: Notification) {
        window.level = AppWindowPlacement.activeWindowLevel
    }

    func windowDidResignKey(_: Notification) {
        window.level = .normal
    }

    func windowWillClose(_: Notification) {
        store.dismissFeedback()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
