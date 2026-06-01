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
    private let shortcuts = ShortcutsController()
    private let preferences = PreferencesWindowController()

    func applicationDidFinishLaunching(_: Notification) {
        let library = LibraryViewModel(store: environment.scriptStore)
        libraryViewModel = library
        let importExportVM = ImportExportViewModel(store: environment.scriptStore, libraryViewModel: library)
        importExportViewModel = importExportVM
        let setsVM = SetsViewModel(promptSetStore: environment.promptSetStore, scriptStore: environment.scriptStore)

        let windowController = MainWindowController(
            environment: environment,
            libraryViewModel: library,
            importExportViewModel: importExportVM,
            setsViewModel: setsVM
        )
        mainWindowController = windowController
        windowController.onStartPrompter = { [weak self] script in self?.showPrompter(script) }

        prompterController = PrompterWindowController(store: environment.scriptStore)
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
        menuBarController = makeMenuBarController(windowController: windowController, importExportVM: importExportVM)
        configureShortcuts()
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
        menuBar.onToggleVoice = { [weak self] in self?.prompterController?.toggleVoiceMode() }
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

    private func recentScriptsForMenu() -> [Script] {
        (try? environment.scriptStore.recent(limit: 8)) ?? []
    }

    private func showPreferences() {
        preferences.show()
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
