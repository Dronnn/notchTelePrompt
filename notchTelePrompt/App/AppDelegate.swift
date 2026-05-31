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

    func applicationDidFinishLaunching(_: Notification) {
        let windowController = MainWindowController(environment: environment)
        mainWindowController = windowController

        let menuBar = MenuBarController()
        menuBar.windowController = windowController
        menuBar.onNewScript = { [weak windowController] in windowController?.open() }
        menuBarController = menuBar
    }
}
