//
//  PrompterStyle.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics

/// default prompter appearance constants for the rendered text surface.
/// these become user-customizable in phase 10; for now they are sensible fixed defaults
/// matching ScriptPrompterSettings's defaults.
nonisolated enum PrompterStyle {
    /// fallback point size for the prompter text (an explicitly sized surface, not Dynamic Type);
    /// per-script sizes override this at render time via PrompterFontSize.
    static let fontSize = CGFloat(PrompterFontSize.default)
    /// vertical spacing between rendered lines.
    static let lineSpacing: CGFloat = 8
    /// height of the subtle progress bar at the bottom edge.
    static let progressBarHeight: CGFloat = 3
}
