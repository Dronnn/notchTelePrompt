//
//  SetNavigatorPanel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// the floating window that lists the active set's prompts during a session.
/// never becomes key or main, so picking the next script does not steal focus from the user's active app.
final class SetNavigatorPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: SetNavigatorPanelConfiguration.styleMask,
            backing: .buffered,
            defer: false
        )
        self.contentView = contentView
        SetNavigatorPanelConfiguration.apply(to: self)
    }

    // MARK: - Focus

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
