//
//  SetNavigatorWindowController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// owns the floating set navigator panel and its hosted SwiftUI content for the app's lifetime.
/// shows and hides the panel without ever taking focus, docks it to the left edge of the camera
/// screen on first show, and forwards script selections to the prompter via onSelectScript.
@MainActor
final class SetNavigatorWindowController: NSObject {
    /// the navigator's size on first show; afterwards the user can resize it freely by dragging an edge.
    private static let defaultPanelSize = CGSize(width: 260, height: 360)

    private let panel: SetNavigatorPanel
    private let viewModel: SetNavigatorViewModel

    var isVisible: Bool {
        panel.isVisible
    }

    /// forwards the script the user picks in the navigator so the host can show it in the prompter.
    var onSelectScript: ((Script) -> Void)? {
        get { viewModel.onSelectScript }
        set { viewModel.onSelectScript = newValue }
    }

    init(promptSetStore: PromptSetStore, scriptStore: ScriptStore) {
        let viewModel = SetNavigatorViewModel(promptSetStore: promptSetStore, scriptStore: scriptStore)
        self.viewModel = viewModel

        let hostingView = PrompterHostingView(rootView: SetNavigatorView(viewModel: viewModel))
        // don't let SwiftUI's intrinsic sizing drive the window's content min/max size; the panel's own
        // minSize and free user resizing should govern, so clear the default .standardBounds options.
        hostingView.sizingOptions = []
        let panel = SetNavigatorPanel(contentView: hostingView)
        panel.setContentSize(Self.defaultPanelSize)
        // let the user drag the navigator anywhere on its background; never makes the panel key.
        panel.isMovableByWindowBackground = true
        panel.acceptsMouseMovedEvents = true
        self.panel = panel

        super.init()
    }

    // MARK: - Presentation

    /// loads the active set, docks the navigator to the left edge, and shows it without taking focus.
    func show() {
        viewModel.refresh()
        dockToLeftEdge()
        // orderFront (never makeKeyAndOrderFront) keeps the panel non-activating and focus-safe.
        panel.orderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    /// reloads the active set's contents; call when the active set changes while already visible.
    func refresh() {
        viewModel.refresh()
    }

    /// reloads and ensures the navigator is shown for the current active set.
    func showActiveSet() {
        show()
    }

    // MARK: - Positioning

    /// docks the navigator to the left edge of the camera screen, vertically centered, at the
    /// current (possibly user-resized) size.
    private func dockToLeftEdge() {
        guard let screen = DisplayProvider.cameraScreen() else {
            return
        }
        let visibleFrame = screen.visibleFrame
        let size = panel.frame.size
        let x = visibleFrame.minX
        let y = visibleFrame.midY - size.height / 2
        panel.setFrame(CGRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }
}
