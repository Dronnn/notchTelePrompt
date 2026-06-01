//
//  MenuBarController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// owns the menu bar status item and its menu.
/// menu actions forward to closures set by the app delegate (new/import/paste/export, show/snap
/// prompter, library); preferences is wired in phase 10.
@MainActor
final class MenuBarController: NSObject {
    weak var windowController: MainWindowController?
    var onNewScript: (() -> Void)?
    var onImportScript: (() -> Void)?
    var onPasteClipboard: (() -> Void)?
    var onExportScript: (() -> Void)?
    var onShowPrompter: (() -> Void)?
    var onSnapToNotch: (() -> Void)?
    var onToggleNavigator: (() -> Void)?
    /// reports the prompter's current visibility so the menu can show the right Show / Hide title.
    var isPrompterVisible: (() -> Bool)?
    /// reports the set navigator's visibility so the menu can show the right Show / Hide title.
    var isNavigatorVisible: (() -> Bool)?

    private let statusItem: NSStatusItem
    /// kept so the title can be flipped between "Show Prompter" and "Hide Prompter" as the menu opens.
    private var showPrompterItem: NSMenuItem?
    /// kept so the title can be flipped between "Show Set Navigator" and "Hide Set Navigator".
    private var showNavigatorItem: NSMenuItem?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        let menu = makeMenu()
        menu.delegate = self
        statusItem.menu = menu
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
        let showPrompterItem = menuItem(title: String(localized: "Show Prompter"), action: #selector(showPrompter))
        self.showPrompterItem = showPrompterItem
        menu.addItem(showPrompterItem)
        menu.addItem(menuItem(title: String(localized: "Snap Prompter to Notch"), action: #selector(snapToNotch)))
        let showNavigatorItem = menuItem(
            title: String(localized: "Show Set Navigator"),
            action: #selector(toggleNavigator)
        )
        self.showNavigatorItem = showNavigatorItem
        menu.addItem(showNavigatorItem)
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

    @objc
    private func snapToNotch() {
        onSnapToNotch?()
    }

    @objc
    private func toggleNavigator() {
        onToggleNavigator?()
    }

    // TODO: wire to the preferences window in phase 10.
    @objc
    private func openPreferences() {}

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSMenuDelegate

extension MenuBarController: NSMenuDelegate {
    /// flips the prompter item title to reflect whether the overlay is currently visible.
    func menuNeedsUpdate(_: NSMenu) {
        let prompterVisible = isPrompterVisible?() ?? false
        showPrompterItem?.title = prompterVisible
            ? String(localized: "Hide Prompter")
            : String(localized: "Show Prompter")
        let navigatorVisible = isNavigatorVisible?() ?? false
        showNavigatorItem?.title = navigatorVisible
            ? String(localized: "Hide Set Navigator")
            : String(localized: "Show Set Navigator")
    }
}
