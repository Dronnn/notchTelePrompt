//
//  PrompterLayoutMetrics.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics

/// pure geometry for the offset-driven prompter layout: how tall the rendered lines are, how far
/// the content can scroll, and the mapping between a scroll offset and the current reading line.
///
/// the layout pads the line stack by half the viewport at top and bottom (breathing room, folds in
/// deferred 6.6) so the first and last lines can sit centered in the viewport. the scroll `offset`
/// is the distance the content has travelled upward, measured so that at offset 0 line 0 is centered
/// and at `maxOffset` the last line is centered.
///
/// nonisolated and stateless so both the engine and nonisolated tests can use it.
nonisolated enum PrompterLayoutMetrics {
    /// vertical advance per line: the glyph box plus the spacing below it.
    static func lineHeight(fontSize: Double, lineSpacing: Double) -> Double {
        fontSize + lineSpacing
    }

    /// total height of the rendered line stack (no breathing room): `n` line boxes with `n-1` gaps.
    /// zero for an empty script.
    static func contentHeight(lineCount: Int, fontSize: Double, lineSpacing: Double) -> Double {
        guard lineCount > 0 else {
            return 0
        }
        let lines = Double(lineCount)
        return lines * fontSize + (lines - 1) * lineSpacing
    }

    /// the largest scroll offset, i.e. the distance from line 0 centered to the last line centered.
    /// equals the line-center span (`(lineCount - 1) * lineHeight`); never negative. the viewport
    /// height is accepted for symmetry with the breathing-room model but does not change the max,
    /// because the half-viewport padding on both ends cancels out between the two centered states.
    static func maxOffset(
        contentHeight: Double,
        viewportHeight: Double,
        fontSize: Double,
        lineSpacing: Double
    ) -> Double {
        _ = viewportHeight
        guard contentHeight > fontSize else {
            return 0
        }
        // contentHeight - fontSize == (lineCount - 1) * lineHeight, the first-center to last-center span.
        return max(contentHeight - fontSize, 0)
    }

    /// the scroll offset that centers the line at `index` (clamped into `0...maxOffset`).
    static func offset(forLineIndex index: Int, fontSize: Double, lineSpacing: Double, maxOffset: Double) -> Double {
        let raw = Double(max(index, 0)) * lineHeight(fontSize: fontSize, lineSpacing: lineSpacing)
        return min(max(raw, 0), maxOffset)
    }

    /// the index of the line currently centered for the given scroll offset, clamped to the script's
    /// valid range. rounds to the nearest line so emphasis snaps to whichever line is closest to center.
    static func lineIndex(forOffset offset: Double, lineCount: Int, fontSize: Double, lineSpacing: Double) -> Int {
        guard lineCount > 0 else {
            return 0
        }
        let step = lineHeight(fontSize: fontSize, lineSpacing: lineSpacing)
        guard step > 0 else {
            return 0
        }
        let index = Int((max(offset, 0) / step).rounded())
        return min(max(index, 0), lineCount - 1)
    }
}
