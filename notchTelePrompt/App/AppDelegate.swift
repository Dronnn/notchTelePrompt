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
    private var libraryViewModel: LibraryViewModel?

    func applicationDidFinishLaunching(_: Notification) {
        let library = LibraryViewModel(store: environment.scriptStore)
        libraryViewModel = library
        let importExportVM = ImportExportViewModel(store: environment.scriptStore, libraryViewModel: library)
        importExportViewModel = importExportVM

        let windowController = MainWindowController(
            environment: environment,
            libraryViewModel: library,
            importExportViewModel: importExportVM
        )
        mainWindowController = windowController
        windowController.onStartPrompter = { [weak self] script in self?.showPrompter(script) }

        prompterController = PrompterWindowController()
        library.onScriptDeleted = { [weak self] id in self?.prompterController?.forgetScript(id) }
        menuBarController = makeMenuBarController(windowController: windowController, importExportVM: importExportVM)
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

    /// menu-bar toggle: hide if visible; else reopen the last script, then the selection, then the most
    /// recent; open the library only when there is nothing to show.
    private func togglePrompter() {
        guard let prompter = prompterController else {
            return
        }
        if prompter.isVisible {
            prompter.hide()
            return
        }
        let script = prompter.lastScript
            ?? libraryViewModel?.selectedScript
            ?? environment.scriptStore.mostRecentScript
        if let script {
            showPrompter(script)
        } else {
            mainWindowController?.open()
        }
    }
}
