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

    func applicationDidFinishLaunching(_: Notification) {
        let libraryViewModel = LibraryViewModel(store: environment.scriptStore)
        let importExportVM = ImportExportViewModel(store: environment.scriptStore, libraryViewModel: libraryViewModel)
        importExportViewModel = importExportVM

        let windowController = MainWindowController(
            environment: environment,
            libraryViewModel: libraryViewModel,
            importExportViewModel: importExportVM
        )
        mainWindowController = windowController

        let menuBar = MenuBarController()
        menuBar.windowController = windowController
        menuBar.onNewScript = { [weak windowController] in windowController?.open() }
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
        menuBarController = menuBar
    }
}
