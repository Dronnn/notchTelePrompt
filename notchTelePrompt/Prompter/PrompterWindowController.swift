//
//  PrompterWindowController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// owns the prompter overlay panel and its hosted SwiftUI content for the app's lifetime.
/// shows and hides the panel without ever taking focus, and persists the last-visibility flag.
@MainActor
final class PrompterWindowController {
    private let panel: PrompterPanel
    private let viewModel: PrompterViewModel
    private let visibilityStore: PrompterVisibilityStore

    var isVisible: Bool {
        panel.isVisible
    }

    init(defaults: UserDefaults = .standard) {
        let viewModel = PrompterViewModel()
        self.viewModel = viewModel
        visibilityStore = PrompterVisibilityStore(defaults: defaults)

        let hostingView = NSHostingView(rootView: PrompterContentView(viewModel: viewModel))
        panel = PrompterPanel(contentView: hostingView)
    }

    // MARK: - Presentation

    func show(script: Script) {
        viewModel.currentScript = script
        positionPanel()
        // orderFront (never makeKeyAndOrderFront) keeps the panel non-activating and focus-safe.
        panel.orderFront(nil)
        visibilityStore.setVisible(true)
    }

    func hide() {
        panel.orderOut(nil)
        visibilityStore.setVisible(false)
    }

    func toggle(script: Script?) {
        if isVisible {
            hide()
        } else if let script {
            show(script: script)
        }
    }

    // MARK: - Positioning

    private func positionPanel() {
        // TODO: phase 5 replaces this with notch/edge geometry from DisplayProvider.
        // placeholder: center the panel horizontally at the top of the main screen.
        guard let screen = NSScreen.main else {
            return
        }
        let screenFrame = screen.frame
        let panelWidth: CGFloat = 600
        let panelHeight: CGFloat = 80
        let x = screenFrame.midX - panelWidth / 2
        let y = screenFrame.maxY - panelHeight
        panel.setContentSize(NSSize(width: panelWidth, height: panelHeight))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
