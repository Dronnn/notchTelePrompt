//
//  MainWindowController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// owns the main library/editor window, hosting the SwiftUI MainView in an NSWindow.
/// the app is an LSUIElement, so the window is opened on demand from the menu bar rather than at launch.
@MainActor
final class MainWindowController {
    private let window: NSWindow

    init(
        environment: AppEnvironment,
        libraryViewModel: LibraryViewModel,
        importExportViewModel: ImportExportViewModel
    ) {
        let hostingController = NSHostingController(
            rootView: MainView(
                environment: environment,
                libraryViewModel: libraryViewModel,
                importExportViewModel: importExportViewModel
            )
        )
        window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = String(localized: "NotchPrompter")
        window.setContentSize(NSSize(width: 900, height: 600))
        window.center()
        // the controller outlives a closed window, so reopening must not use a deallocated instance.
        window.isReleasedWhenClosed = false
    }

    // MARK: - Presentation

    func open() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
