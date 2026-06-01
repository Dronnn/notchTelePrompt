//
//  PrompterFontSize.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// single source of truth for the prompter font-size range, step and clamping math.
/// pure and nonisolated so both the view models and the rendering layer can share it.
nonisolated enum PrompterFontSize {
    /// fallback point size used when a script has no stored font size yet.
    static let `default`: Double = 28
    static let min: Double = 14
    static let max: Double = 96
    static let step: Double = 2

    /// constrains a size to the allowed range.
    static func clamp(_ size: Double) -> Double {
        Swift.min(Swift.max(size, min), max)
    }

    /// the next larger size, clamped to max.
    static func incremented(_ size: Double) -> Double {
        clamp(size + step)
    }

    /// the next smaller size, clamped to min.
    static func decremented(_ size: Double) -> Double {
        clamp(size - step)
    }
}
