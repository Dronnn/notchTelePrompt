//
//  PrompterPreset.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// one-tap appearance bundles for the prompter defaults pane. each preset returns a full
/// ScriptPrompterSettings, reusing the type's defaults for any field it doesn't deliberately change.
/// displayMode is left at its default everywhere (positioning isn't surfaced in v1.0).
enum PrompterPreset: String, CaseIterable, Identifiable {
    case compact
    case comfortable
    case largeText
    case minimalBackground
    case highContrast

    var id: String {
        rawValue
    }

    var title: LocalizedStringKey {
        switch self {
        case .compact: "Compact"
        case .comfortable: "Comfortable"
        case .largeText: "Large Text"
        case .minimalBackground: "Minimal Background"
        case .highContrast: "High Contrast"
        }
    }

    /// the settings bundle this preset applies. starts from the defaults and overrides only what matters.
    var settings: ScriptPrompterSettings {
        var settings = ScriptPrompterSettings()
        switch self {
        case .compact:
            settings.fontSize = 20
            settings.lineSpacing = 4
        case .comfortable:
            settings.fontSize = 28
            settings.lineSpacing = 8
        case .largeText:
            settings.fontSize = 48
            settings.lineSpacing = 12
        case .minimalBackground:
            settings.backgroundOpacity = 0.4
        case .highContrast:
            settings.backgroundOpacity = 1.0
            settings.textColorHex = "#FFFFFF"
        }
        return settings
    }
}
