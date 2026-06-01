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
nonisolated struct ScriptPrompterSettings: Codable, Equatable {
    var fontSize = PrompterFontSize.default
    var lineSpacing: Double = 8
    var textColorHex = "#FFFFFF"
    var backgroundOpacity: Double = 0.85
    var scrollSpeed: Double = 150
    var displayMode: PrompterDisplayMode = .notch
    var alignment: PrompterAlignment = .center
}

extension ScriptPrompterSettings {
    /// a tolerant decoder so a blob persisted before a field existed still loads: a missing key falls
    /// back to that property's default. synthesized Decodable would instead throw keyNotFound.
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? fontSize
        lineSpacing = try container.decodeIfPresent(Double.self, forKey: .lineSpacing) ?? lineSpacing
        textColorHex = try container.decodeIfPresent(String.self, forKey: .textColorHex) ?? textColorHex
        backgroundOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? backgroundOpacity
        scrollSpeed = try container.decodeIfPresent(Double.self, forKey: .scrollSpeed) ?? scrollSpeed
        displayMode = try container.decodeIfPresent(PrompterDisplayMode.self, forKey: .displayMode) ?? displayMode
        alignment = try container.decodeIfPresent(PrompterAlignment.self, forKey: .alignment) ?? alignment
    }
}
