//
//  Script.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import SwiftData

/// a user teleprompter script stored in SwiftData.
/// settingsBlob holds optional per-script prompter settings (used from v1.1; nil means use global defaults).
@Model
final class Script {
    var id = UUID()
    var title: String = ""
    var text: String = ""
    var createdAt = Date.now
    var updatedAt = Date.now
    var lastUsedAt: Date?
    var isFavorite: Bool = false
    var settingsBlob: ScriptPrompterSettings?

    init(
        id: UUID = UUID(),
        title: String = "",
        text: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastUsedAt: Date? = nil,
        isFavorite: Bool = false,
        settingsBlob: ScriptPrompterSettings? = nil
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
        self.settingsBlob = settingsBlob
    }
}
