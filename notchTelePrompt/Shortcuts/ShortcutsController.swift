//
//  ShortcutsController.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import KeyboardShortcuts

/// registers the global hotkey handlers and forwards each to a closure set by the app delegate.
/// keeps hotkey wiring out of the delegate and mirrors MenuBarController's closure-based pattern.
/// the shortcuts are global carbon hotkeys (no accessibility permission needed); `onKeyDown` fires
/// once per press, not on key repeat.
@MainActor
final class ShortcutsController {
    var onTogglePrompter: (() -> Void)?
    var onStartPause: (() -> Void)?
    var onRestart: (() -> Void)?
    var onSpeedUp: (() -> Void)?
    var onSpeedDown: (() -> Void)?
    var onNextScript: (() -> Void)?
    var onPreviousScript: (() -> Void)?
    var onOpenEditor: (() -> Void)?

    /// installs the handlers; call once at launch after the closures are set.
    func register() {
        KeyboardShortcuts.onKeyDown(for: .togglePrompter) { [weak self] in self?.onTogglePrompter?() }
        KeyboardShortcuts.onKeyDown(for: .startPausePrompter) { [weak self] in self?.onStartPause?() }
        KeyboardShortcuts.onKeyDown(for: .restartPrompter) { [weak self] in self?.onRestart?() }
        KeyboardShortcuts.onKeyDown(for: .speedUpPrompter) { [weak self] in self?.onSpeedUp?() }
        KeyboardShortcuts.onKeyDown(for: .speedDownPrompter) { [weak self] in self?.onSpeedDown?() }
        KeyboardShortcuts.onKeyDown(for: .nextScript) { [weak self] in self?.onNextScript?() }
        KeyboardShortcuts.onKeyDown(for: .previousScript) { [weak self] in self?.onPreviousScript?() }
        KeyboardShortcuts.onKeyDown(for: .openEditor) { [weak self] in self?.onOpenEditor?() }
    }
}
