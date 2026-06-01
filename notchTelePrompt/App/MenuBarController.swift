//
//  MenuBarController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import KeyboardShortcuts

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
    var onStartPause: (() -> Void)?
    var onRestart: (() -> Void)?
    var onStop: (() -> Void)?
    var onToggleVoice: (() -> Void)?
    var isVoiceEnabled: (() -> Bool)?
    var onToggleControlPanel: (() -> Void)?
    var onOpenPreferences: (() -> Void)?
    var onShowScript: ((Script) -> Void)?
    /// supplies the recent scripts shown in the Open Recent submenu, rebuilt each time the menu opens.
    var recentScripts: (() -> [Script])?
    /// reports whether the prompter is currently playing, for the dynamic Start / Pause title.
    var isPrompterPlaying: (() -> Bool)?
    /// reports whether the mini control panel is visible, for its dynamic Show / Hide title.
    var isControlPanelVisible: (() -> Bool)?
    /// reports the prompter's current visibility so the menu can show the right Show / Hide title.
    var isPrompterVisible: (() -> Bool)?
    /// reports the set navigator's visibility so the menu can show the right Show / Hide title.
    var isNavigatorVisible: (() -> Bool)?

    private let statusItem: NSStatusItem
    /// kept so the title can be flipped between "Show Prompter" and "Hide Prompter" as the menu opens.
    private var showPrompterItem: NSMenuItem?
    /// kept so the title can be flipped between "Show Set Navigator" and "Hide Set Navigator".
    private var showNavigatorItem: NSMenuItem?
    private var startPauseItem: NSMenuItem?
    private var voiceItem: NSMenuItem?
    private var recentMenuItem: NSMenuItem?
    private var showControlPanelItem: NSMenuItem?

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
        addScriptItems(to: menu)
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "Show Library"), action: #selector(showLibrary)))
        let showPrompterItem = menuItem(title: String(localized: "Show Prompter"), action: #selector(showPrompter))
        showPrompterItem.setShortcut(for: .togglePrompter)
        self.showPrompterItem = showPrompterItem
        menu.addItem(showPrompterItem)
        menu.addItem(menuItem(title: String(localized: "Snap Prompter to Notch"), action: #selector(snapToNotch)))
        let showNavigatorItem = menuItem(
            title: String(localized: "Show Set Navigator"),
            action: #selector(toggleNavigator)
        )
        self.showNavigatorItem = showNavigatorItem
        menu.addItem(showNavigatorItem)
        addPlaybackItems(to: menu)
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "Preferences…"), action: #selector(openPreferences)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: String(localized: "Quit NotchPrompter"), action: #selector(quit)))
        for item in menu.items where item.action != nil {
            item.target = self
        }
        return menu
    }

    /// adds the script-management group: new, import, paste-as-script and export, with their local
    /// key equivalents.
    private func addScriptItems(to menu: NSMenu) {
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
    }

    /// adds the playback group: start/pause, restart, stop, the Open Recent submenu and the mini-controls
    /// toggle. start/pause and restart mirror their global hotkeys via setShortcut so the menu stays in sync.
    private func addPlaybackItems(to menu: NSMenu) {
        menu.addItem(.separator())
        let startPauseItem = menuItem(title: String(localized: "Start"), action: #selector(startPause))
        startPauseItem.setShortcut(for: .startPausePrompter)
        self.startPauseItem = startPauseItem
        menu.addItem(startPauseItem)
        let restartItem = menuItem(title: String(localized: "Restart"), action: #selector(restart))
        restartItem.setShortcut(for: .restartPrompter)
        menu.addItem(restartItem)
        menu.addItem(menuItem(title: String(localized: "Stop"), action: #selector(stop)))
        let voiceItem = menuItem(title: String(localized: "Start Voice Follow"), action: #selector(toggleVoice))
        self.voiceItem = voiceItem
        menu.addItem(voiceItem)
        let recentItem = NSMenuItem(title: String(localized: "Open Recent"), action: nil, keyEquivalent: "")
        recentItem.submenu = NSMenu()
        recentMenuItem = recentItem
        menu.addItem(recentItem)
        let showControlPanelItem = menuItem(
            title: String(localized: "Show Mini Controls"),
            action: #selector(toggleControlPanel)
        )
        self.showControlPanelItem = showControlPanelItem
        menu.addItem(showControlPanelItem)
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

    @objc
    private func startPause() {
        onStartPause?()
    }

    @objc
    private func restart() {
        onRestart?()
    }

    @objc
    private func stop() {
        onStop?()
    }

    @objc
    private func toggleVoice() {
        onToggleVoice?()
    }

    @objc
    private func toggleControlPanel() {
        onToggleControlPanel?()
    }

    @objc
    private func selectRecent(_ sender: NSMenuItem) {
        guard let script = sender.representedObject as? Script else {
            return
        }
        onShowScript?(script)
    }

    @objc
    private func openPreferences() {
        onOpenPreferences?()
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSMenuDelegate

extension MenuBarController: NSMenuDelegate {
    /// while the status-bar menu is open the thread is in tracking mode, which buffers global carbon
    /// hotkeys and then replays them on dismissal — so the items that mirror a global shortcut via
    /// setShortcut would double-fire. disable those shortcuts while the menu is up, per KeyboardShortcuts.
    func menuWillOpen(_: NSMenu) {
        KeyboardShortcuts.disable(.togglePrompter, .startPausePrompter, .restartPrompter)
    }

    func menuDidClose(_: NSMenu) {
        KeyboardShortcuts.enable(.togglePrompter, .startPausePrompter, .restartPrompter)
    }

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
        startPauseItem?.title = (isPrompterPlaying?() ?? false)
            ? String(localized: "Pause")
            : String(localized: "Start")
        voiceItem?.title = (isVoiceEnabled?() ?? false)
            ? String(localized: "Stop Voice Follow")
            : String(localized: "Start Voice Follow")
        showControlPanelItem?.title = (isControlPanelVisible?() ?? false)
            ? String(localized: "Hide Mini Controls")
            : String(localized: "Show Mini Controls")
        rebuildRecentMenu()
    }

    /// repopulates the Open Recent submenu from the supplied recent scripts each time the menu opens.
    private func rebuildRecentMenu() {
        guard let submenu = recentMenuItem?.submenu else {
            return
        }
        submenu.removeAllItems()
        let scripts = recentScripts?() ?? []
        guard !scripts.isEmpty else {
            let empty = NSMenuItem(title: String(localized: "No Recent Scripts"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
            return
        }
        for script in scripts {
            let title = script.title.isEmpty ? String(localized: "Untitled Script") : script.title
            let item = NSMenuItem(title: title, action: #selector(selectRecent(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = script
            submenu.addItem(item)
        }
    }
}
