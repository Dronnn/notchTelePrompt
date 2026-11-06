//
//  WindowCapturePrivacyController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// applies the legacy capture-exclusion request to app windows, including alerts and panels.
/// macOS and sharing apps may ignore this flag; it is not a capture-prevention guarantee.
@MainActor
final class WindowCapturePrivacyController: NSObject {
    func start() {
        for window in NSApp.windows {
            Self.configure(window)
        }
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didChangeOcclusionStateNotification] {
            NotificationCenter.default.addObserver(
                self, selector: #selector(windowAppeared(_:)), name: name, object: nil
            )
        }
    }

    static func configure(_ window: NSWindow) {
        window.sharingType = .none
    }

    @objc
    private func windowAppeared(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        Self.configure(window)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
