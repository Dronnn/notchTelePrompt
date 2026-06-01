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
    /// the overlay's size on first show; afterwards the user can resize it freely by dragging an edge.
    private static let defaultPanelSize = CGSize(width: 640, height: 120)

    private let panel: PrompterPanel
    private let viewModel: PrompterViewModel
    private let visibilityStore: PrompterVisibilityStore

    var isVisible: Bool {
        panel.isVisible
    }

    init(store: ScriptStore, preferences: PreferencesStore, defaults: UserDefaults = .standard) {
        let viewModel = PrompterViewModel(store: store, preferences: preferences)
        self.viewModel = viewModel
        visibilityStore = PrompterVisibilityStore(defaults: defaults)

        let hostingView = PrompterHostingView(rootView: PrompterContentView(
            viewModel: viewModel,
            onClose: {},
            onSnap: {}
        ))
        // clear the default sizing options so SwiftUI's intrinsic size never feeds the window.
        hostingView.sizingOptions = []
        // host the SwiftUI view inside a plain container that is the panel's content view, filling it via
        // autoresizing. as a *direct* content view, NSHostingView sized the panel to the script's full
        // rendered height and looped AppKit's constraint passes until it threw; behind a container the
        // window size is owned only by snap-to-notch and user resizing, never by the content.
        let container = NSView(frame: NSRect(origin: .zero, size: Self.defaultPanelSize))
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = container.bounds
        container.addSubview(hostingView)
        let panel = PrompterPanel(contentView: container)
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
        viewModel.setOverlayVisible(true)
    }

    /// re-presents the already-loaded overlay without resetting the script or the scroll position,
    /// so the mini panel's show toggle brings the prompter back exactly where it left off.
    func revealPrompter() {
        guard viewModel.currentScript != nil else {
            return
        }
        snapToNotch()
        panel.orderFront(nil)
        visibilityStore.setVisible(true)
        viewModel.setOverlayVisible(true)
    }

    func hide() {
        // releasing the mic here covers forgetScript too (it routes through hide), so voice-follow never
        // keeps capturing once the overlay is gone and its on-screen mic indicator disappears.
        viewModel.disableVoiceMode()
        panel.orderOut(nil)
        visibilityStore.setVisible(false)
        viewModel.setOverlayVisible(false)
    }

    /// flips the overlay between shown and hidden; used by the mini control panel's show/hide toggle.
    func togglePrompterVisibility() {
        if isVisible {
            hide()
        } else {
            revealPrompter()
        }
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

    /// drops the overlay's script and hides it; used when clearing all local data removes every script.
    func forgetAll() {
        hide()
        viewModel.currentScript = nil
    }

    // MARK: - Playback controls

    /// whether the engine is actively scrolling; drives the menu's dynamic Start / Pause title.
    var isPlaying: Bool {
        viewModel.scrollEngine.state == .playing
    }

    /// play/pause the current script, honoring the configured countdown; no-op when nothing is loaded.
    func playPause() {
        guard viewModel.currentScript != nil else {
            return
        }
        viewModel.playPause()
    }

    func restart() {
        guard viewModel.currentScript != nil else {
            return
        }
        viewModel.restart()
    }

    func stop() {
        viewModel.stop()
    }

    func increaseSpeed() {
        guard viewModel.currentScript != nil else {
            return
        }
        viewModel.increaseSpeed()
    }

    func decreaseSpeed() {
        guard viewModel.currentScript != nil else {
            return
        }
        viewModel.decreaseSpeed()
    }

    // MARK: - Voice

    var isVoiceModeEnabled: Bool {
        viewModel.isVoiceModeEnabled
    }

    func toggleVoiceMode() {
        viewModel.toggleVoiceMode()
    }

    /// forwards the view model's microphone-denied callback so the app delegate can show guidance.
    var onVoicePermissionDenied: (() -> Void)? {
        get { viewModel.onVoicePermissionDenied }
        set { viewModel.onVoicePermissionDenied = newValue }
    }

    /// forwards the view model's mic-unavailable callback so the app delegate can let the user know.
    var onVoiceUnavailable: (() -> Void)? {
        get { viewModel.onVoiceUnavailable }
        set { viewModel.onVoiceUnavailable = newValue }
    }

    // MARK: - Mini control panel

    /// the optional floating control panel; created on first use, sharing this overlay's view model.
    private lazy var controlPanelController: PrompterControlPanelController = {
        let controller = PrompterControlPanelController(viewModel: viewModel)
        controller.onTogglePrompter = { [weak self] in self?.togglePrompterVisibility() }
        return controller
    }()

    var isControlPanelVisible: Bool {
        controlPanelController.isVisible
    }

    func toggleControlPanel() {
        controlPanelController.toggle()
    }

    // MARK: - Positioning

    private func snapToNotch() {
        guard let screen = DisplayProvider.cameraScreen() else {
            return
        }
        let metrics = DisplayProvider.metrics(for: screen)
        // preserve the current (possibly user-resized) size and only reposition under the notch;
        // the calculator clamps to the visible frame so an oversized window still fits.
        let frame = PrompterFrameCalculator.frame(in: metrics, size: panel.frame.size)
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
