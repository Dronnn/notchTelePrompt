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

    /// set by the app delegate after construction; the editor's Start Prompter button reads it at call time.
    var onStartPrompter: ((Script) -> Void)?

    init(
        environment: AppEnvironment,
        libraryViewModel: LibraryViewModel,
        importExportViewModel: ImportExportViewModel
    ) {
        // forward through a stable closure so late assignment of onStartPrompter is still picked up.
        var forwardStart: ((Script) -> Void)?
        let forwardToController: (Script) -> Void = { script in forwardStart?(script) }
        let hostingController = NSHostingController(
            rootView: MainView(
                environment: environment,
                libraryViewModel: libraryViewModel,
                importExportViewModel: importExportViewModel,
                onStartPrompter: forwardToController
            )
        )
        window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = String(localized: "NotchPrompter")
        window.setContentSize(NSSize(width: 900, height: 600))
        window.center()
        // the controller outlives a closed window, so reopening must not use a deallocated instance.
        window.isReleasedWhenClosed = false

        forwardStart = { [weak self] script in self?.onStartPrompter?(script) }
    }

    // MARK: - Presentation

    func open() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
