//
//  PrompterPanelConfiguration.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// pure configuration values and the panel-configuration routine for the prompter overlay.
/// kept separate from the panel itself so the chosen window traits can be asserted in unit tests
/// without constructing the full window controller.
enum PrompterPanelConfiguration {
    // MARK: - Window Traits

    /// .statusBar (level 25) floats above normal and full-screen app windows without obscuring the
    /// system menu bar or notification center; .floating (3) is insufficient over full-screen apps.
    static let windowLevel: NSWindow.Level = .statusBar

    /// .borderless removes all chrome; .nonactivatingPanel keeps the panel from activating the app
    /// when it is ordered front or clicked, so the user's frontmost app stays active.
    static let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]

    /// .fullScreenAuxiliary keeps the panel visible over full-screen apps; .stationary stops Mission
    /// Control from grouping or moving it. the panel stays on the current Space (no .canJoinAllSpaces);
    /// an all-Spaces option can be added later behind a preference.
    static let collectionBehavior: NSWindow.CollectionBehavior = [
        .fullScreenAuxiliary,
        .stationary
    ]

    /// requests best-effort exclusion from native screen-capture paths. macOS treats .none as a legacy
    /// value and may ignore it, so exclusion is not guaranteed and must be verified per system / recorder.
    static let defaultSharingType: NSWindow.SharingType = .none

    /// honest disclosure of the limits of capture exclusion, surfaced in preferences from phase 10.
    static let captureExclusionDisclosure = String(localized: """
    The prompter overlay requests best-effort exclusion from screen capture (NSWindow.sharingType = .none). \
    On some systems it may be hidden from certain native capture paths, but macOS does not guarantee this. \
    Depending on your macOS version and the recording or virtual-camera app (including Screenshot and \
    QuickTime Player), the overlay may still be captured. Verify with your own setup before relying on it.
    """)

    // MARK: - Configuration

    /// applies all overlay window traits to the panel; transparency is set so the hosted SwiftUI view
    /// controls its own background, and sharingType is set here (before first display) so exclusion takes effect.
    static func apply(to panel: NSPanel) {
        // isFloatingPanel resets the window level to .floating, so set it before the explicit level.
        panel.isFloatingPanel = true
        panel.level = windowLevel
        panel.collectionBehavior = collectionBehavior
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        apply(sharingType: defaultSharingType, to: panel)
    }

    /// future hook for the phase 10 preferences toggle that lets the user disable capture exclusion
    /// by switching to .readOnly.
    static func apply(sharingType: NSWindow.SharingType, to panel: NSPanel) {
        panel.sharingType = sharingType
    }
}
