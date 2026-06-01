//
//  PrompterControlPanelConfiguration.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// pure configuration values and the panel-configuration routine for the optional mini control panel.
/// kept separate from the panel so the chosen window traits can be asserted in unit tests
/// without constructing the full window controller. mirrors PrompterPanelConfiguration.
enum PrompterControlPanelConfiguration {
    // MARK: - Window Traits

    /// one level above the prompter overlay so the controls always float over it (and over all
    /// normal and full-screen app windows), letting the user steer playback during a session.
    static let windowLevel = NSWindow.Level(rawValue: PrompterPanelConfiguration.windowLevel.rawValue + 1)

    /// .borderless removes all chrome; .nonactivatingPanel keeps the panel from activating the app when
    /// ordered front or clicked, so the user's frontmost app stays active. no .resizable: the control
    /// row has a fixed size and is only moved, not resized.
    static let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]

    /// .fullScreenAuxiliary keeps the panel visible over full-screen apps; .stationary stops Mission
    /// Control from grouping or moving it. the panel stays on the current Space (no .canJoinAllSpaces).
    static let collectionBehavior: NSWindow.CollectionBehavior = [
        .fullScreenAuxiliary,
        .stationary
    ]

    /// requests best-effort exclusion from native screen-capture paths, matching the prompter overlay so
    /// the controls stay private. macOS treats .none as a legacy value and may ignore it, so exclusion
    /// is not guaranteed and must be verified per system / recorder.
    static let defaultSharingType: NSWindow.SharingType = .none

    // MARK: - Configuration

    /// applies all control-panel window traits to the panel; transparency is set so the hosted SwiftUI view
    /// controls its own background, and sharingType is set here (before first display) so exclusion takes effect.
    static func apply(to panel: NSPanel) {
        // isFloatingPanel resets the window level to .floating, so set it before the explicit level.
        panel.isFloatingPanel = true
        panel.level = windowLevel
        panel.collectionBehavior = collectionBehavior
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        apply(sharingType: defaultSharingType, to: panel)
    }

    /// future hook for the preferences toggle that lets the user disable capture exclusion by switching to .readOnly.
    static func apply(sharingType: NSWindow.SharingType, to panel: NSPanel) {
        panel.sharingType = sharingType
    }
}
