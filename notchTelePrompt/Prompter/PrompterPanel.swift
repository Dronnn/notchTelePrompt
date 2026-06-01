//
//  PrompterPanel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// the floating overlay window that hosts the prompter content.
/// never becomes key or main, so it cannot steal focus from the user's active app while recording.
final class PrompterPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: PrompterPanelConfiguration.styleMask,
            backing: .buffered,
            defer: false
        )
        self.contentView = contentView
        PrompterPanelConfiguration.apply(to: self)
    }

    // MARK: - Focus

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
