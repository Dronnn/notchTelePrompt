//
//  WindowCapturePrivacyTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
@testable import notchTelePrompt
import Testing

@MainActor
struct WindowCapturePrivacyTests {
    @Test
    func newlyPresentedWindowsReceiveTheCaptureExclusionRequest() {
        let controller = WindowCapturePrivacyController()
        controller.start()
        let window = NSWindow(
            contentRect: .zero, styleMask: .titled, backing: .buffered, defer: false
        )
        window.sharingType = .readOnly

        NotificationCenter.default.post(name: NSWindow.didBecomeKeyNotification, object: window)

        #expect(window.sharingType == .none)
        #expect(window.styleMask.contains(.titled))
        withExtendedLifetime(controller) {}
    }
}
