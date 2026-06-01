//
//  PrompterFrameCalculator.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics

/// computes the prompter panel's on-screen frame: centered horizontally and tucked just below the
/// notch / menu bar. pure and deterministic so the geometry can be unit-tested without NSScreen.
/// nonisolated as a whole so members carry no actor isolation and avoid a swiftformat/swiftlint
/// ordering conflict on a per-member nonisolated keyword.
nonisolated enum PrompterFrameCalculator {
    /// vertical gap between the notch / menu bar and the top edge of the panel.
    static let topGap: CGFloat = 4

    /// returns the panel frame for the given screen metrics and panel size, clamped into visibleFrame.
    static func frame(in metrics: PrompterScreenMetrics, size: CGSize) -> CGRect {
        // never let the panel exceed the usable area, so a too-large size can't bleed off-screen.
        let cappedSize = CGSize(
            width: min(size.width, metrics.visibleFrame.width),
            height: min(size.height, metrics.visibleFrame.height)
        )

        // center horizontally on the full screen.
        let x = metrics.frame.midX - cappedSize.width / 2

        // the top edge sits just below the notch when present, otherwise below the menu bar.
        let topY = metrics.safeAreaTopInset > 0
            ? metrics.frame.maxY - metrics.safeAreaTopInset
            : metrics.visibleFrame.maxY

        // origin is bottom-left in AppKit, so drop by the gap and the panel height.
        let y = topY - topGap - cappedSize.height

        let clampedX = clamp(
            x,
            lower: metrics.visibleFrame.minX,
            upper: metrics.visibleFrame.maxX - cappedSize.width
        )
        let clampedY = clamp(
            y,
            lower: metrics.visibleFrame.minY,
            upper: metrics.visibleFrame.maxY - cappedSize.height
        )

        return CGRect(origin: CGPoint(x: clampedX, y: clampedY), size: cappedSize)
    }

    /// clamps value into [lower, upper]; if the range is inverted (panel larger than the screen),
    /// the lower bound wins so the panel pins to the screen's bottom-left rather than off-screen.
    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard upper > lower else {
            return lower
        }
        return min(max(value, lower), upper)
    }
}
