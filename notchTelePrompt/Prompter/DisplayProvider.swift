//
//  DisplayProvider.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import CoreGraphics

/// selects the target screen for the prompter overlay and reads its geometry into PrompterScreenMetrics.
/// prefers the notched display, then the built-in display, so the overlay lands near the MacBook camera.
@MainActor
enum DisplayProvider {
    // MARK: - Screen Selection

    /// the first screen reporting a top safe-area inset, i.e. a notched display.
    static func notchScreen() -> NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 }
    }

    /// the built-in display, identified through its CGDirectDisplayID.
    static func builtInScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let id = displayID(for: screen) else {
                return false
            }
            return CGDisplayIsBuiltin(id) != 0
        }
    }

    /// best screen for the prompter: notched, else built-in, else the main/first screen.
    static func cameraScreen() -> NSScreen? {
        notchScreen() ?? builtInScreen() ?? NSScreen.main ?? NSScreen.screens.first
    }

    // MARK: - Metrics

    static func metrics(for screen: NSScreen) -> PrompterScreenMetrics {
        PrompterScreenMetrics(
            frame: screen.frame,
            visibleFrame: screen.visibleFrame,
            safeAreaTopInset: screen.safeAreaInsets.top
        )
    }

    // MARK: - Helpers

    /// reads the CGDirectDisplayID from a screen's device description without force-unwrapping.
    private static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = screen.deviceDescription[key] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}
