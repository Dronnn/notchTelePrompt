//
//  PrompterFrameCalculatorTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics
import Foundation
@testable import notchTelePrompt
import Testing

struct PrompterFrameCalculatorTests {
    /// a roomy notched screen: 1512x982 with a 37pt menu bar/notch inset at the top.
    private func notchedMetrics() -> PrompterScreenMetrics {
        PrompterScreenMetrics(
            frame: CGRect(x: 0, y: 0, width: 1_512, height: 982),
            visibleFrame: CGRect(x: 0, y: 0, width: 1_512, height: 945),
            safeAreaTopInset: 37
        )
    }

    /// a screen without a notch: the visibleFrame top sits below the 25pt menu bar.
    private func plainMetrics() -> PrompterScreenMetrics {
        PrompterScreenMetrics(
            frame: CGRect(x: 0, y: 0, width: 1_920, height: 1_080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1_920, height: 1_055),
            safeAreaTopInset: 0
        )
    }

    // MARK: - Horizontal Centering

    @Test
    func frameIsCenteredHorizontally() {
        let metrics = notchedMetrics()
        let size = CGSize(width: 640, height: 120)
        let frame = PrompterFrameCalculator.frame(in: metrics, size: size)
        #expect(abs(frame.midX - metrics.frame.midX) < 0.001)
    }

    // MARK: - Notch Positioning

    @Test
    func topEdgeSitsBelowNotch() {
        let metrics = notchedMetrics()
        let size = CGSize(width: 640, height: 120)
        let frame = PrompterFrameCalculator.frame(in: metrics, size: size)
        let belowNotch = metrics.frame.maxY - metrics.safeAreaTopInset
        // the panel top must not poke above (be greater than) the area just below the notch.
        #expect(frame.maxY <= belowNotch)
    }

    // MARK: - No-Notch Positioning

    @Test
    func topEdgeSitsBelowMenuBarWhenNoNotch() {
        let metrics = plainMetrics()
        let size = CGSize(width: 640, height: 120)
        let frame = PrompterFrameCalculator.frame(in: metrics, size: size)
        #expect(frame.maxY <= metrics.visibleFrame.maxY)
    }

    // MARK: - Clamping

    @Test
    func oversizedFrameIsClampedWithinVisibleFrame() {
        let metrics = notchedMetrics()
        // wider and taller than the whole screen.
        let size = CGSize(width: 4_000, height: 4_000)
        let frame = PrompterFrameCalculator.frame(in: metrics, size: size)
        #expect(frame.minX == metrics.visibleFrame.minX)
        #expect(frame.minY == metrics.visibleFrame.minY)
        // the panel is capped to the usable area, so it never exceeds the visible frame.
        #expect(frame.width <= metrics.visibleFrame.width)
        #expect(frame.height <= metrics.visibleFrame.height)
    }

    @Test
    func frameStaysWithinVisibleFrameHorizontally() {
        // an offset screen (e.g. a secondary display) so minX is non-zero.
        let metrics = PrompterScreenMetrics(
            frame: CGRect(x: -1_000, y: 0, width: 800, height: 600),
            visibleFrame: CGRect(x: -1_000, y: 0, width: 800, height: 575),
            safeAreaTopInset: 0
        )
        let size = CGSize(width: 640, height: 120)
        let frame = PrompterFrameCalculator.frame(in: metrics, size: size)
        #expect(frame.minX >= metrics.visibleFrame.minX)
        #expect(frame.maxX <= metrics.visibleFrame.maxX + 0.001)
        #expect(frame.minY >= metrics.visibleFrame.minY)
        #expect(frame.maxY <= metrics.visibleFrame.maxY + 0.001)
    }
}
