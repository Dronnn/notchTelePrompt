//
//  PrompterScreenMetrics.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics

/// the screen geometry the prompter positioning math needs, captured as plain values.
/// kept free of NSScreen so the frame calculation can be exercised deterministically in unit tests.
/// nonisolated so the pure calculator and the unit tests can read it outside the main actor.
nonisolated struct PrompterScreenMetrics {
    /// the full screen frame, including the menu bar and notch area (AppKit bottom-left origin).
    let frame: CGRect
    /// the usable frame excluding the menu bar and Dock.
    let visibleFrame: CGRect
    /// the height of the notch / safe-area inset at the top; 0 when the screen has no notch.
    let safeAreaTopInset: CGFloat
}
