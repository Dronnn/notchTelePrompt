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
final class MainWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let hostingController: NSHostingController<MainView>

    /// set by the app delegate after construction; the editor's Start Prompter button reads it at call time.
    var onStartPrompter: ((Script) -> Void)?
    var onSupport: (() -> Void)?

    init(
        environment: AppEnvironment,
        libraryViewModel: LibraryViewModel,
        importExportViewModel: ImportExportViewModel,
        setsViewModel: SetsViewModel
    ) {
        // forward through a stable closure so late assignment of onStartPrompter is still picked up.
        var forwardStart: ((Script) -> Void)?
        var forwardSupport: (() -> Void)?
        let forwardToController: (Script) -> Void = { script in forwardStart?(script) }
        let hostingController = NSHostingController(
            rootView: MainView(
                environment: environment,
                libraryViewModel: libraryViewModel,
                importExportViewModel: importExportViewModel,
                setsViewModel: setsViewModel,
                onStartPrompter: forwardToController,
                onSupport: { forwardSupport?() }
            )
        )
        self.hostingController = hostingController

        // wrap the SwiftUI content so Finder file drops work anywhere in the window, including
        // the library and sets sidebars where the editor's own drop target is not present.
        let container = FileDropContainerView(frame: .zero)
        let hostedView = hostingController.view
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: container.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        container.onDropFileURL = { [weak importExportViewModel] url in
            guard let importExportViewModel else {
                return false
            }
            Task { await importExportViewModel.handleDroppedFileAsNewScript(url: url) }
            return true
        }
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = container
        window.title = String(localized: "NotchPrompter")
        window.identifier = AppWindowPlacement.libraryIdentifier
        window.isMovableByWindowBackground = true
        window.setContentSize(NSSize(width: 900, height: 600))
        window.center()
        // the controller outlives a closed window, so reopening must not use a deallocated instance.
        window.isReleasedWhenClosed = false

        super.init()
        window.delegate = self

        forwardStart = { [weak self] script in self?.onStartPrompter?(script) }
        forwardSupport = { [weak self] in self?.onSupport?() }
    }

    // MARK: - Presentation

    var isVisible: Bool {
        window.isVisible
    }

    func open() {
        AppWindowPlacement.place(window)
        window.level = AppWindowPlacement.activeWindowLevel
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        // the SwiftUI editor creates its NSTextView after the window is shown; remove file-URL drag
        // acceptance there so Finder drops fall through to the window-level importer.
        DispatchQueue.main.async { [weak self] in
            self?.removeTextEditorFileDropTargets()
        }
    }

    func windowDidBecomeKey(_: Notification) {
        window.level = AppWindowPlacement.activeWindowLevel
        removeTextEditorFileDropTargets()
    }

    /// lets the editor keep normal text drags but not swallow Finder file drops, which belong to the
    /// window-level drop target.
    private func removeTextEditorFileDropTargets() {
        guard let contentView = window.contentView else {
            return
        }
        Self.removeFileURLDropTargets(in: contentView)
    }

    private static func removeFileURLDropTargets(in view: NSView) {
        if let textView = view as? NSTextView, textView.registeredDraggedTypes.contains(.fileURL) {
            let types = textView.registeredDraggedTypes.filter { $0 != .fileURL }
            textView.unregisterDraggedTypes()
            textView.registerForDraggedTypes(types)
        }
        for subview in view.subviews {
            removeFileURLDropTargets(in: subview)
        }
    }

    func windowDidResignKey(_: Notification) {
        window.level = .normal
    }

    /// flips the library/editor window between shown and hidden; used by the prompter's library toggle.
    func toggle() {
        if isVisible {
            window.orderOut(nil)
        } else {
            open()
        }
    }
}
