//
//  ScriptPrompterSettings.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// per-script prompter appearance and behavior, persisted as a codable blob on Script.
/// the v1.0 app uses global defaults; this leaves room for per-script settings in v1.1.
struct ScriptPrompterSettings: Codable, Equatable {
    var fontSize: Double
    var lineSpacing: Double
    var textColorHex: String
    var backgroundOpacity: Double
    var scrollSpeed: Double
    var displayMode: PrompterDisplayMode
    var alignment: PrompterAlignment

    init(
        fontSize: Double = 28,
        lineSpacing: Double = 8,
        textColorHex: String = "#FFFFFF",
        backgroundOpacity: Double = 0.85,
        scrollSpeed: Double = 150,
        displayMode: PrompterDisplayMode = .notch,
        alignment: PrompterAlignment = .center
    ) {
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.textColorHex = textColorHex
        self.backgroundOpacity = backgroundOpacity
        self.scrollSpeed = scrollSpeed
        self.displayMode = displayMode
        self.alignment = alignment
    }
}
