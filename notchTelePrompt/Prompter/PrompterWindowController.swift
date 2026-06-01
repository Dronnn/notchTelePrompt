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
/// shows and hides the panel without ever taking focus, positions it below the notch, and
/// keeps the last-shown script so the overlay can be reopened after a close.
@MainActor
final class PrompterWindowController: NSObject {
    /// default overlay size; one source of truth so positioning and reset stay consistent.
    private static let defaultPanelSize = CGSize(width: 640, height: 120)

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

        let hostingView = PrompterHostingView(rootView: PrompterContentView(
            viewModel: viewModel,
            onClose: {},
            onSnap: {}
        ))
        let panel = PrompterPanel(contentView: hostingView)
        panel.setContentSize(Self.defaultPanelSize)
        // let the user drag the overlay anywhere on its background; never makes the panel key.
        panel.isMovableByWindowBackground = true
        panel.acceptsMouseMovedEvents = true
        self.panel = panel

        super.init()

        // rebuild the content with controls wired now that self is fully initialized.
        hostingView.rootView = PrompterContentView(
            viewModel: viewModel,
            onClose: { [weak self] in self?.hide() },
            onSnap: { [weak self] in self?.snap() }
        )

        observeScreenChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Presentation

    func show(script: Script) {
        viewModel.currentScript = script
        snapToNotch()
        // orderFront (never makeKeyAndOrderFront) keeps the panel non-activating and focus-safe.
        panel.orderFront(nil)
        visibilityStore.setVisible(true)
    }

    func hide() {
        panel.orderOut(nil)
        visibilityStore.setVisible(false)
    }

    /// the most recently shown script, retained across hide so the overlay can be reopened.
    var lastScript: Script? {
        viewModel.currentScript
    }

    /// re-runs positioning; used by the snap-to-notch control even while already visible.
    func snap() {
        snapToNotch()
    }

    /// drops the overlay's reference to a script (and hides it) once that script no longer exists.
    func forgetScript(_ id: UUID) {
        guard viewModel.currentScript?.id == id else {
            return
        }
        hide()
        viewModel.currentScript = nil
    }

    // MARK: - Positioning

    private func snapToNotch() {
        guard let screen = DisplayProvider.cameraScreen() else {
            return
        }
        let metrics = DisplayProvider.metrics(for: screen)
        // always start from the preferred size so a cap on a small display doesn't shrink later snaps.
        let frame = PrompterFrameCalculator.frame(in: metrics, size: Self.defaultPanelSize)
        panel.setFrame(frame, display: true)
    }

    // MARK: - Screen Changes

    /// re-snaps when displays are added/removed or rearranged, so the overlay stays under the notch.
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
        snapToNotch()
    }
}
