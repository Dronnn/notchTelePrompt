//
//  MenuBarController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// owns the menu bar status item and its menu.
/// actions are stubs for now; real behavior is wired in later phases (editor, prompter, voice).
@MainActor
final class MenuBarController {
    weak var windowController: MainWindowController?
    var onNewScript: (() -> Void)?
    var onImportScript: (() -> Void)?
    var onPasteClipboard: (() -> Void)?
    var onExportScript: (() -> Void)?
    var onShowPrompter: (() -> Void)?

    private let statusItem: NSStatusItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureButton()
        statusItem.menu = makeMenu()
    }

    // MARK: - Setup

    private func configureButton() {
        guard let button = statusItem.button else {
            return
        }
        let image = NSImage(
            systemSymbolName: "text.alignleft",
            accessibilityDescription: String(localized: "NotchPrompter")
        )
        image?.isTemplate = true
        button.image = image
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem(title: String(localized: "New Script"), action: #selector(newScript)))
        menu.addItem(menuItem(
            title: String(localized: "Import…"),
            action: #selector(importScript),
            keyEquivalent: "i",
            modifiers: [.command, .shift]
        ))
        menu.addItem(menuItem(
            title: String(localized: "Paste as Script"),
            action: #selector(pasteClipboard),
            keyEquivalent: "v",
            modifiers: [.command, .shift]
        ))
        menu.addItem(menuItem(
            title: String(localized: "Export…"),
            action: #selector(exportScript),
            keyEquivalent: "e",
            modifiers: [.command]
        ))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "Show Library"), action: #selector(showLibrary)))
        menu.addItem(menuItem(title: String(localized: "Show Prompter"), action: #selector(showPrompter)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "Preferences…"), action: #selector(openPreferences)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "Quit NotchPrompter"), action: #selector(quit)))
        for item in menu.items where item.action != nil {
            item.target = self
        }
        return menu
    }

    private func menuItem(
        title: String,
        action: Selector,
        keyEquivalent: String = "",
        modifiers: NSEvent.ModifierFlags = []
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    // MARK: - Actions

    @objc
    private func newScript() {
        onNewScript?()
    }

    @objc
    private func importScript() {
        onImportScript?()
    }

    @objc
    private func pasteClipboard() {
        onPasteClipboard?()
    }

    @objc
    private func exportScript() {
        onExportScript?()
    }

    @objc
    private func showLibrary() {
        windowController?.open()
    }

    @objc
    private func showPrompter() {
        onShowPrompter?()
    }

    // TODO: wire to the preferences window in phase 10.
    @objc
    private func openPreferences() {}

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
