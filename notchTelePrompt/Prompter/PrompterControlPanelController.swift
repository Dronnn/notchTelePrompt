//
//  PrompterControlPanelController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// owns the optional floating mini control panel and its hosted SwiftUI content.
/// shows and hides the panel without ever taking focus, docks it near the bottom of the camera
/// screen, and forwards the show/hide-prompter toggle to the host via onTogglePrompter.
@MainActor
final class PrompterControlPanelController: NSObject {
    /// the control row's fixed size; wide enough for the eight icon buttons in a single line.
    private static let panelSize = CGSize(width: 440, height: 48)

    /// gap between the panel's bottom edge and the visible frame's bottom edge.
    private static let bottomMargin: CGFloat = 24

    private let panel: PrompterControlPanel
    private let viewModel: PrompterViewModel
    private let preferences: PreferencesStore
    private let dragMonitor: PanelDragMonitor

    /// forwards the user's request to show or hide the prompter overlay from the control panel.
    var onTogglePrompter: (() -> Void)?

    var isVisible: Bool {
        panel.isVisible
    }

    init(viewModel: PrompterViewModel, preferences: PreferencesStore) {
        self.viewModel = viewModel
        self.preferences = preferences

        let hostingView = PrompterHostingView(
            rootView: AppLanguageRoot(preferencesStore: preferences) {
                PrompterControlPanelView(viewModel: viewModel, onTogglePrompter: {}, onClose: {})
            }
        )
        // don't let SwiftUI's intrinsic sizing drive the window's content size; the fixed panel size governs.
        hostingView.sizingOptions = []
        let panel = PrompterControlPanel(contentView: hostingView)
        panel.setContentSize(Self.panelSize)
        // the hosting view swallows background clicks; the monitor turns a drag into performDrag
        // and still forwards plain clicks. never makes the panel key.
        panel.isMovableByWindowBackground = true
        panel.acceptsMouseMovedEvents = true
        self.panel = panel
        dragMonitor = PanelDragMonitor(panel: panel)

        super.init()

        // rebuild the content with the toggle action wired now that self is fully initialized.
        hostingView.rootView = AppLanguageRoot(preferencesStore: preferences) {
            PrompterControlPanelView(
                viewModel: viewModel,
                onTogglePrompter: { [weak self] in self?.onTogglePrompter?() },
                onClose: { [weak self] in self?.hide() }
            )
        }

        observeScreenChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Presentation

    func show() {
        positionNearBottom()
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

    // MARK: - Positioning

    /// centers the control row horizontally on the camera screen and places it near the bottom,
    /// just above the visible frame, at the panel's current size.
    private func positionNearBottom() {
        guard let screen = DisplayProvider.cameraScreen() else {
            return
        }
        let visibleFrame = screen.visibleFrame
        let size = panel.frame.size
        let x = visibleFrame.midX - size.width / 2
        let y = visibleFrame.minY + Self.bottomMargin
        AppWindowPlacement.place(panel, preferredFrame: CGRect(x: x, y: y, width: size.width, height: size.height))
    }

    // MARK: - Screen Changes

    /// reposition when displays change so the panel never strands off-screen.
    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    /// didChangeScreenParametersNotification posts on the main thread, matching this type's isolation.
    @objc
    private func screenParametersDidChange(_: Notification) {
        guard isVisible else {
            return
        }
        positionNearBottom()
    }
}
