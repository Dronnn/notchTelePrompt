//
//  ScriptFontSizeChange.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// preference-change broadcasts that let a live prompter react without the preferences pane holding a
/// reference to it.
extension Notification.Name {
    /// broadcast when the voice sensitivity or silence delay preference changes, so a live prompter can
    /// retune the running voice engine without the preferences pane holding a reference to it.
    static let preferencesVoiceConfigDidChange = Notification.Name("preferencesVoiceConfigDidChange")

    /// broadcast when the global prompter appearance defaults change, so a live prompter can react to the
    /// changed field (font, line spacing, scroll speed) without the pane holding a reference to it.
    static let preferencesPrompterDefaultsDidChange = Notification.Name("preferencesPrompterDefaultsDidChange")
}
