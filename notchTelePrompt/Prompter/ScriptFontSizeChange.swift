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

    /// broadcast when the voice sensitivity or silence delay preference changes, so a live prompter can
    /// retune the running voice engine without the preferences pane holding a reference to it.
    static let preferencesVoiceConfigDidChange = Notification.Name("preferencesVoiceConfigDidChange")

    /// broadcast when the global prompter appearance defaults change, so a live prompter can re-seed its
    /// scroll speed and recompute line-spacing-driven geometry without the pane holding a reference to it.
    static let preferencesPrompterDefaultsDidChange = Notification.Name("preferencesPrompterDefaultsDidChange")
}

/// userInfo key for the changed script's id on a scriptFontSizeDidChange notification.
nonisolated enum ScriptFontSizeChange {
    static let scriptIDKey = "scriptID"
}
