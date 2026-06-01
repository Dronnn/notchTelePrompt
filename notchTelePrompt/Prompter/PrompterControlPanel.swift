//
//  PrompterControlPanel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// the optional floating mini control panel that steers the prompter's playback.
/// never becomes key or main, so its buttons do not steal focus from the user's active app while recording.
final class PrompterControlPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: PrompterControlPanelConfiguration.styleMask,
            backing: .buffered,
            defer: false
        )
        self.contentView = contentView
        PrompterControlPanelConfiguration.apply(to: self)
    }

    // MARK: - Focus

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
