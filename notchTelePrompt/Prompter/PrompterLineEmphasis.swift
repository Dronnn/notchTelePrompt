//
//  PrompterLineEmphasis.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// derives per-line emphasis (opacity, current-line flag) and overall reading progress.
/// pure and stateless, so it is usable from any isolation context.
nonisolated enum PrompterLineEmphasis {
    /// lowest opacity a far-away line is dimmed to.
    private static let floorOpacity = 0.4

    /// opacity for a line at the given signed distance from the current line.
    /// distance 0 → 1.0, ±1 → 0.65, ±2 → 0.5, ±3 and beyond → the 0.4 floor.
    static func opacity(distanceFromCurrent distance: Int) -> Double {
        let value: Double = switch abs(distance) {
        case 0:
            1.0
        case 1:
            0.65
        case 2:
            0.5
        default:
            floorOpacity
        }
        return min(max(value, floorOpacity), 1.0)
    }

    /// whether the line at the given signed distance is the current reading line.
    static func isCurrent(_ distance: Int) -> Bool {
        distance == 0
    }

    /// reading progress in [0, 1] for the current line within a script of lineCount lines.
    /// returns 0 when there is at most one line; currentIndex is clamped to the valid range.
    static func progress(currentIndex: Int, lineCount: Int) -> Double {
        guard lineCount > 1 else {
            return 0
        }
        let clampedIndex = min(max(currentIndex, 0), lineCount - 1)
        return Double(clampedIndex) / Double(lineCount - 1)
    }
}
