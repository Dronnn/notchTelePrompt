//
//  ScriptFontSizeChange.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// broadcast when a script's prompter font size changes, so the editor and the overlay stay in sync
/// without holding references to each other. the userInfo carries the affected script id.
extension Notification.Name {
    static let scriptFontSizeDidChange = Notification.Name("scriptFontSizeDidChange")
}

/// userInfo key for the changed script's id on a scriptFontSizeDidChange notification.
nonisolated enum ScriptFontSizeChange {
    static let scriptIDKey = "scriptID"
}
