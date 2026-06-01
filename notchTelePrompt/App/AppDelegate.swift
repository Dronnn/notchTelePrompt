//
//  AppDelegate.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// sets up the menu bar presence at launch and owns the app-wide dependencies.
/// the app is an LSUIElement (no Dock icon), so all entry points come from the status item.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let environment = AppEnvironment()

    private var menuBarController: MenuBarController?
    private var mainWindowController: MainWindowController?
    private var importExportViewModel: ImportExportViewModel?
    private var prompterController: PrompterWindowController?
    private var setNavigatorController: SetNavigatorWindowController?
    private var libraryViewModel: LibraryViewModel?
    private var setsViewModel: SetsViewModel?
    private let shortcuts = ShortcutsController()
    private lazy var preferences = PreferencesWindowController(
        preferencesStore: environment.preferencesStore,
        scriptStore: environment.scriptStore
    )

    func applicationDidFinishLaunching(_: Notification) {
        let library = LibraryViewModel(store: environment.scriptStore)
        libraryViewModel = library
        let importExportVM = ImportExportViewModel(store: environment.scriptStore, libraryViewModel: library)
        importExportViewModel = importExportVM
        let setsVM = SetsViewModel(promptSetStore: environment.promptSetStore, scriptStore: environment.scriptStore)
        setsViewModel = setsVM

        let windowController = MainWindowController(
            environment: environment,
            libraryViewModel: library,
            importExportViewModel: importExportVM,
            setsViewModel: setsVM
        )
        mainWindowController = windowController
        windowController.onStartPrompter = { [weak self] script in self?.showPrompter(script) }

        prompterController = PrompterWindowController(
            store: environment.scriptStore,
            preferences: environment.preferencesStore
        )
        prompterController?.onVoicePermissionDenied = { [weak self] in self?.presentMicrophoneDeniedAlert() }
        prompterController?.onVoiceUnavailable = { [weak self] in self?.presentMicrophoneUnavailableAlert() }

        let navigator = SetNavigatorWindowController(
            promptSetStore: environment.promptSetStore,
            scriptStore: environment.scriptStore
        )
        // selecting a prompt in the floating navigator shows it in the prompter, just like Start Prompter.
        navigator.onSelectScript = { [weak self] script in self?.showPrompter(script) }
        setNavigatorController = navigator

        library.onScriptDeleted = { [weak self] id in self?.prompterController?.forgetScript(id) }
        preferences.onExportAllScripts = { [weak self] in self?.exportAllScripts() }
        preferences.onClearLocalData = { [weak self] in self?.confirmAndClearLocalData() }
        menuBarController = makeMenuBarController(windowController: windowController, importExportVM: importExportVM)
        configureShortcuts()
        applyLaunchPreferences()
    }

    // MARK: - Launch Preferences

    /// applies the startup preferences: Dock visibility, then optionally the editor and the last prompter.
    private func applyLaunchPreferences() {
        let prefs = environment.preferencesStore
        DockIconPolicy.apply(showDockIcon: prefs.showDockIcon)
        if prefs.openEditorOnLaunch {
            mainWindowController?.open()
        }
        if prefs.restoreLastScript {
            restoreLastShownScript()
        }
    }

    /// shows the last-remembered script in the prompter, unless one is already showing.
    /// a missing or unknown id is ignored silently.
    private func restoreLastShownScript() {
        guard prompterController?.isVisible == false else {
            return
        }
        guard let id = environment.preferencesStore.lastShownScriptID else {
            return
        }
        // try? on an optional-returning fetch yields Script??; flatten so a missing id is just nil.
        let script = (try? environment.scriptStore.script(withID: id)).flatMap(\.self)
        guard let script else {
            return
        }
        showPrompter(script)
    }

    // MARK: - Menu Bar

    private func makeMenuBarController(
        windowController: MainWindowController,
        importExportVM: ImportExportViewModel
    ) -> MenuBarController {
        let menuBar = MenuBarController()
        menuBar.windowController = windowController
        menuBar.onNewScript = { [weak windowController] in windowController?.open() }
        menuBar.onShowPrompter = { [weak self] in self?.togglePrompter() }
        menuBar.onSnapToNotch = { [weak self] in self?.prompterController?.snap() }
        menuBar.isPrompterVisible = { [weak self] in self?.prompterController?.isVisible ?? false }
        menuBar.onToggleNavigator = { [weak self] in self?.setNavigatorController?.toggle() }
        menuBar.isNavigatorVisible = { [weak self] in self?.setNavigatorController?.isVisible ?? false }
        menuBar.onStartPause = { [weak self] in self?.startPausePrompter() }
        menuBar.onRestart = { [weak self] in self?.restartPrompter() }
        menuBar.onStop = { [weak self] in self?.prompterController?.stop() }
        menuBar.onToggleVoice = { [weak self] in self?.toggleVoiceFollow() }
        menuBar.isVoiceEnabled = { [weak self] in self?.prompterController?.isVoiceModeEnabled ?? false }
        menuBar.isPrompterPlaying = { [weak self] in self?.prompterController?.isPlaying ?? false }
        menuBar.onToggleControlPanel = { [weak self] in self?.prompterController?.toggleControlPanel() }
        menuBar.isControlPanelVisible = { [weak self] in self?.prompterController?.isControlPanelVisible ?? false }
        menuBar.recentScripts = { [weak self] in self?.recentScriptsForMenu() ?? [] }
        menuBar.onShowScript = { [weak self] script in self?.showPrompter(script) }
        menuBar.onOpenPreferences = { [weak self] in self?.showPreferences() }
        menuBar.onImportScript = { [weak windowController, weak importExportVM] in
            windowController?.open()
            Task { await importExportVM?.importScript() }
        }
        menuBar.onPasteClipboard = { [weak windowController, weak importExportVM] in
            windowController?.open()
            importExportVM?.pasteClipboardAsScript()
        }
        menuBar.onExportScript = { [weak importExportVM] in
            Task { await importExportVM?.exportSelectedScript() }
        }
        return menuBar
    }

    // MARK: - Prompter

    /// shows the prompter for a definite script, marking it used and refreshing the library's recents.
    private func showPrompter(_ script: Script) {
        // markUsed is best-effort recency bookkeeping; failing it must not block starting the prompter.
        try? environment.scriptStore.markUsed(script)
        libraryViewModel?.refresh()
        // remember the last shown script so it can be restored on the next launch.
        environment.preferencesStore.lastShownScriptID = script.id
        prompterController?.show(script: script)
    }

    /// menu-bar toggle: hide if visible; otherwise resolve and show a script (or open the library).
    private func togglePrompter() {
        guard let prompter = prompterController else {
            return
        }
        if prompter.isVisible {
            prompter.hide()
        } else {
            ensurePrompterShowing()
        }
    }

    /// resolves a script to show (last shown, else library selection, else most recent) and shows it.
    /// returns whether a script is now showing; opens the library when there is nothing to show.
    @discardableResult
    private func ensurePrompterShowing() -> Bool {
        guard let prompter = prompterController else {
            return false
        }
        if prompter.isVisible {
            return true
        }
        let script = prompter.lastScript
            ?? libraryViewModel?.selectedScript
            ?? environment.scriptStore.mostRecentScript
        if let script {
            showPrompter(script)
            return true
        }
        mainWindowController?.open()
        return false
    }

    private func startPausePrompter() {
        guard ensurePrompterShowing() else {
            return
        }
        prompterController?.playPause()
    }

    private func restartPrompter() {
        guard ensurePrompterShowing() else {
            return
        }
        prompterController?.restart()
    }

    /// menu toggle for voice-follow; enabling first ensures a prompter is showing so the mic indicator is
    /// visible and there is a script to follow (mirrors start/restart). disabling just turns it off.
    private func toggleVoiceFollow() {
        guard let prompter = prompterController else {
            return
        }
        if prompter.isVoiceModeEnabled {
            prompter.toggleVoiceMode()
        } else {
            guard ensurePrompterShowing() else {
                return
            }
            prompter.toggleVoiceMode()
        }
    }

    private func recentScriptsForMenu() -> [Script] {
        (try? environment.scriptStore.recent(limit: 8)) ?? []
    }

    private func showPreferences() {
        preferences.show()
    }

    // MARK: - Privacy

    /// lets the user pick a folder, then exports every script as a .txt into it (privacy pane).
    /// runs the write in a Task so the panel returns immediately; a write failure shows a brief alert.
    private func exportAllScripts() {
        guard let importExportViewModel else {
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Export")

        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let directory = panel.url else {
            return
        }
        Task {
            await importExportViewModel.exportAllScripts(to: directory)
            if let message = importExportViewModel.errorMessage {
                importExportViewModel.errorMessage = nil
                presentExportAllFailedAlert(message: message)
            }
        }
    }

    /// shows a destructive confirmation, then deletes all scripts and prompt sets and resets dependent
    /// state. on a delete failure it stays honest: a brief alert is shown and dependent state is left
    /// untouched, so a partial clear never crashes the app nor falsely claims success.
    private func confirmAndClearLocalData() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Clear local data?")
        alert.informativeText = String(localized: "Delete all scripts and prompt sets? This can't be undone.")
        let deleteButton = alert.addButton(withTitle: String(localized: "Delete"))
        deleteButton.hasDestructiveAction = true
        alert.addButton(withTitle: String(localized: "Cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }
        do {
            // attempt both deletions; a throw from either aborts the success-only reset below.
            try environment.scriptStore.deleteAll()
            try environment.promptSetStore.deleteAll()
        } catch {
            presentClearDataFailedAlert()
            return
        }
        // deletions succeeded: reset every surface that may still reference a now-deleted model.
        environment.preferencesStore.lastShownScriptID = nil
        prompterController?.forgetAll()
        // the library selection may still point at a deleted script; clear it before refreshing.
        libraryViewModel?.selectedScript = nil
        libraryViewModel?.refresh()
        setsViewModel?.refreshSets()
        setNavigatorController?.refresh()
    }

    /// surfaces a failure during clear-local-data without crashing or claiming success.
    private func presentClearDataFailedAlert() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = String(localized: "Couldn't clear all data")
        alert.informativeText = String(localized: "Some data couldn't be deleted. Please try again.")
        alert.runModal()
    }

    /// surfaces a failure during export-all without crashing; the underlying message comes from the view model.
    private func presentExportAllFailedAlert(message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = String(localized: "Couldn't export all scripts")
        alert.informativeText = message
        alert.runModal()
    }

    /// guides the user to enable microphone access when voice-follow was denied (spec §9.1).
    private func presentMicrophoneDeniedAlert() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = String(localized: "Microphone access is off")
        alert.informativeText = String(
            localized: "Voice-follow needs microphone access. Open System Settings to turn it on, then try again."
        )
        alert.addButton(withTitle: String(localized: "Open System Settings"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    /// lets the user know voice-follow couldn't start the microphone even though access is allowed
    /// (no input device, or the mic is in use by another app).
    private func presentMicrophoneUnavailableAlert() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = String(localized: "Microphone is unavailable")
        alert.informativeText = String(
            localized: "NotchPrompter couldn't start the microphone. It may be in use by another app."
        )
        alert.runModal()
    }

    /// installs the global hotkey handlers, forwarding each to the matching app action.
    private func configureShortcuts() {
        shortcuts.onTogglePrompter = { [weak self] in self?.togglePrompter() }
        shortcuts.onStartPause = { [weak self] in self?.startPausePrompter() }
        shortcuts.onRestart = { [weak self] in self?.restartPrompter() }
        shortcuts.onSpeedUp = { [weak self] in self?.prompterController?.increaseSpeed() }
        shortcuts.onSpeedDown = { [weak self] in self?.prompterController?.decreaseSpeed() }
        shortcuts.onNextScript = { [weak self] in self?.setNavigatorController?.selectNext() }
        shortcuts.onPreviousScript = { [weak self] in self?.setNavigatorController?.selectPrevious() }
        shortcuts.onOpenEditor = { [weak self] in self?.mainWindowController?.open() }
        shortcuts.register()
    }
}
