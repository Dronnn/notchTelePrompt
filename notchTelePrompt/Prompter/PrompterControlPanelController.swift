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
/// screen, and forwards the hide-prompter action to the host via onHidePrompter.
@MainActor
final class PrompterControlPanelController: NSObject {
    /// the control row's fixed size; wide enough for the six icon buttons in a single line.
    private static let panelSize = CGSize(width: 304, height: 48)

    /// gap between the panel's bottom edge and the visible frame's bottom edge.
    private static let bottomMargin: CGFloat = 24

    private let panel: PrompterControlPanel
    private let viewModel: PrompterViewModel

    /// forwards the user's request to hide the prompter overlay from the control panel.
    var onHidePrompter: (() -> Void)?

    var isVisible: Bool {
        panel.isVisible
    }

    init(viewModel: PrompterViewModel) {
        self.viewModel = viewModel

        let hostingView = PrompterHostingView(rootView: PrompterControlPanelView(viewModel: viewModel) {})
        // don't let SwiftUI's intrinsic sizing drive the window's content size; the fixed panel size governs.
        hostingView.sizingOptions = []
        let panel = PrompterControlPanel(contentView: hostingView)
        panel.setContentSize(Self.panelSize)
        // let the user drag the controls anywhere on their background; never makes the panel key.
        panel.isMovableByWindowBackground = true
        panel.acceptsMouseMovedEvents = true
        self.panel = panel

        super.init()

        // rebuild the content with the hide action wired now that self is fully initialized.
        hostingView.rootView = PrompterControlPanelView(viewModel: viewModel) { [weak self] in
            self?.onHidePrompter?()
        }
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
        panel.setFrame(CGRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }
}
