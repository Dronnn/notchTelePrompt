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

    /// local key-event monitor for the overlay's font shortcuts; installed only while the overlay is visible.
    private var fontKeyMonitor: Any?

    /// forwards the set-navigator toggle to the host, which owns the navigator window.
    var onToggleNavigator: (() -> Void)?

    /// forwards the library and preferences toggles to the host, which owns those windows.
    var onToggleLibrary: (() -> Void)?
    var onTogglePreferences: (() -> Void)?

    var isVisible: Bool {
        panel.isVisible
    }

    /// builds a hosting view that fills the panel's container via autoresizing; its intrinsic size never
    /// feeds the window (sizingOptions = []), so the window size is owned only by snap-to-notch and resizing.
    private static func makeHostingView<Content: View>(
        _ rootView: Content,
        frame: NSRect
    ) -> PrompterHostingView<Content> {
        let view = PrompterHostingView(rootView: rootView)
        view.sizingOptions = []
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [.width, .height]
        view.frame = frame
        return view
    }

    /// installs the control-row host pinned to the top-right of the container, sized to the pill via its
    /// intrinsic content size, so it covers only the controls; everywhere else clicks, scroll and
    /// window-background drags reach the text host beneath. layered above the text host, it also clears the
    /// scroll-catcher's native subview, which composites above any sibling swiftui overlay in the text host.
    private func installControlsHost(in container: NSView) {
        let host = PrompterHostingView(rootView: PrompterControlsView(
            viewModel: viewModel,
            onClose: { [weak self] in self?.hide() },
            onSnap: { [weak self] in self?.snap() },
            onToggleNavigator: { [weak self] in self?.onToggleNavigator?() },
            onToggleControlPanel: { [weak self] in self?.toggleControlPanel() },
            onToggleLibrary: { [weak self] in self?.onToggleLibrary?() },
            onTogglePreferences: { [weak self] in self?.onTogglePreferences?() }
        ))
        host.sizingOptions = [.intrinsicContentSize]
        host.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(host)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        // never let the window shrink below the control row's width, so no control is ever clipped.
        panel.minSize = NSSize(
            width: max(PrompterPanelConfiguration.minSize.width, host.fittingSize.width),
            height: PrompterPanelConfiguration.minSize.height
        )
    }

    init(store: ScriptStore, preferences: PreferencesStore, defaults: UserDefaults = .standard) {
        let viewModel = PrompterViewModel(store: store, preferences: preferences)
        self.viewModel = viewModel
        visibilityStore = PrompterVisibilityStore(defaults: defaults)

        // behind a plain container (not a direct content view) the window size is owned only by
        // snap-to-notch and user resizing, never by the SwiftUI content's intrinsic height.
        let container = NSView(frame: NSRect(origin: .zero, size: Self.defaultPanelSize))

        // the text body fills the container.
        let hostingView = Self.makeHostingView(PrompterContentView(viewModel: viewModel), frame: container.bounds)
        container.addSubview(hostingView)

        // the non-interactive chrome (countdown, progress bar, voice indicator) sits in its own host above
        // the text body, so the scroll-catcher's native subview can't hide it; hit-testing is off in the
        // chrome's swiftui content, so scroll and clicks pass straight through to the text body beneath.
        let chromeHost = Self.makeHostingView(PrompterChromeView(viewModel: viewModel), frame: container.bounds)
        container.addSubview(chromeHost)

        let panel = PrompterPanel(contentView: container)
        panel.setContentSize(Self.defaultPanelSize)
        // let the user drag the overlay anywhere on its background; never makes the panel key.
        panel.isMovableByWindowBackground = true
        panel.acceptsMouseMovedEvents = true
        self.panel = panel

        super.init()

        // become the panel's delegate so user resizes are persisted via windowDidEndLiveResize.
        panel.delegate = self

        // host the control row above the text body, pinned to the top-right (see installControlsHost);
        // this also raises the panel's minimum width to fit the row.
        installControlsHost(in: container)

        // restore the last user-set size so the overlay reopens at its remembered dimensions, clamped to
        // the minimum so no control is clipped; the hosting views track the new size via layout.
        if let savedSize = visibilityStore.size {
            panel.setContentSize(CGSize(
                width: max(savedSize.width, panel.minSize.width),
                height: max(savedSize.height, panel.minSize.height)
            ))
        }

        observeScreenChanges()
    }

    deinit {
        // the local key monitor is torn down in hide(); this controller owns the overlay for the app's
        // lifetime, so by the time it deinits the process is terminating and the monitor is already gone.
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Presentation

    func show(script: Script) {
        viewModel.currentScript = script
        snapToNotch()
        // orderFront (never makeKeyAndOrderFront) keeps the panel non-activating and focus-safe.
        panel.orderFront(nil)
        installFontKeyMonitor()
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
        installFontKeyMonitor()
        visibilityStore.setVisible(true)
        viewModel.setOverlayVisible(true)
    }

    func hide() {
        // releasing the mic here covers forgetScript too (it routes through hide), so voice-follow never
        // keeps capturing once the overlay is gone and its on-screen mic indicator disappears.
        viewModel.disableVoiceMode()
        removeFontKeyMonitor()
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

    // MARK: - Font shortcuts

    /// ⌘+ / ⌘= grow and ⌘- / ⌘_ shrink the global font while the overlay is showing, so the shortcuts
    /// work on the prompter when NotchPrompter is the active app. gated on NSApp.isActive (not panel key
    /// status) so we only consume the keys while our app is frontmost — a local monitor never sees another
    /// app's events, and the panel stays non-key, so this never steals focus from the user's recording app.
    private func installFontKeyMonitor() {
        guard fontKeyMonitor == nil else {
            return
        }
        fontKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // assumeIsolated returns a Sendable Bool; the non-Sendable NSEvent is returned outside it.
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard let self, NSApp.isActive else {
                    return false
                }
                let flags = event.modifierFlags.intersection([.command, .option, .control])
                guard flags == .command else {
                    return false
                }
                switch event.charactersIgnoringModifiers {
                case "=", "+":
                    self.viewModel.increaseFontSize()
                    return true
                case "-", "_":
                    self.viewModel.decreaseFontSize()
                    return true
                default:
                    return false
                }
            }
            return handled ? nil : event
        }
    }

    private func removeFontKeyMonitor() {
        guard let monitor = fontKeyMonitor else {
            return
        }
        NSEvent.removeMonitor(monitor)
        fontKeyMonitor = nil
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

// MARK: - NSWindowDelegate

extension PrompterWindowController: NSWindowDelegate {
    /// persists the overlay's size only after the user finishes a drag-resize, so it is restored on relaunch.
    /// using didEndLiveResize (not didResize) means the programmatic clamp in snapToNotch — e.g. when the
    /// overlay opens on a smaller display — never overwrites the user's preferred size.
    func windowDidEndLiveResize(_: Notification) {
        visibilityStore.setSize(panel.frame.size)
    }
}
