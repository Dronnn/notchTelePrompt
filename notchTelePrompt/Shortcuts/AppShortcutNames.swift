//
//  AppShortcutNames.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import KeyboardShortcuts

/// global hotkey names. defaults follow the spec §20 suggestions. the extra names (next/previous
/// script, open editor) deliberately have no default so we don't capture too many shortcuts — users
/// can bind them in preferences. KeyboardShortcuts persists every binding to UserDefaults for us.
extension KeyboardShortcuts.Name {
    static let togglePrompter = Self("togglePrompter", default: .init(.space, modifiers: [.option, .shift]))
    static let startPausePrompter = Self("startPausePrompter", default: .init(.space, modifiers: [.option]))
    static let restartPrompter = Self("restartPrompter", default: .init(.r, modifiers: [.option]))
    static let speedUpPrompter = Self("speedUpPrompter", default: .init(.upArrow, modifiers: [.option]))
    static let speedDownPrompter = Self("speedDownPrompter", default: .init(.downArrow, modifiers: [.option]))
    static let nextScript = Self("nextScript")
    static let previousScript = Self("previousScript")
    static let openEditor = Self("openEditor")
}
