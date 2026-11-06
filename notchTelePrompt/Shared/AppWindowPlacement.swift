//
//  AppWindowPlacement.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

@MainActor
enum AppWindowPlacement {
    static let activeWindowLevel = NSWindow.Level(rawValue: PrompterPanelConfiguration.windowLevel.rawValue + 2)
    static let libraryIdentifier = NSUserInterfaceItemIdentifier("library")
    static let preferencesIdentifier = NSUserInterfaceItemIdentifier("preferences")
    static let supportIdentifier = NSUserInterfaceItemIdentifier("support")

    static func place(_ window: NSWindow, preferredFrame: CGRect? = nil) {
        WindowCapturePrivacyController.configure(window)
        let preferred = preferredFrame ?? window.frame
        let center = CGPoint(x: preferred.midX, y: preferred.midY)
        guard
            let screen = NSScreen.screens.first(where: { $0.frame.contains(center) })
            ?? window.screen ?? DisplayProvider.cameraScreen()
        else {
            return
        }
        let others = NSApp.windows.filter {
            $0 !== window && $0.isVisible && !$0.isMiniaturized && $0.isOnActiveSpace && isManaged($0)
                && $0.frame.intersects(screen.visibleFrame)
        }
        let occupied = others.map(\.frame)
        var frame = AppWindowFrameCalculator.frame(
            preferred: preferred, visibleFrame: screen.visibleFrame, avoiding: occupied
        )
        if occupied.contains(where: { $0.intersects(frame) }) {
            frame = makeRoom(for: preferred, on: screen, among: others) ?? frame
        }
        window.setFrame(frame, display: true)
    }

    private static func isManaged(_ window: NSWindow) -> Bool {
        window is PrompterPanel || window is SetNavigatorPanel || window is PrompterControlPanel
            || window.identifier == libraryIdentifier || window.identifier == preferencesIdentifier
            || window.identifier == supportIdentifier
    }

    /// move a blocking editor/settings window only when that creates a completely clear layout.
    private static func makeRoom(for preferred: CGRect, on screen: NSScreen, among others: [NSWindow]) -> CGRect? {
        for blocker in others where blocker.styleMask.contains(.titled) {
            let fixed = others.filter { $0 !== blocker }.map(\.frame)
            if let arrangement = AppWindowFrameCalculator.makingRoom(
                for: preferred, moving: blocker.frame, in: screen.visibleFrame, avoiding: fixed
            ) {
                blocker.setFrame(arrangement.existing, display: true)
                return arrangement.opening
            }
        }
        return nil
    }
}
