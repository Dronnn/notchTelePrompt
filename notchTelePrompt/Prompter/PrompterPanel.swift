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
        registerForDraggedTypes([.fileURL])
    }

    // MARK: - File drop

    /// NSWindow is a candidate destination once registered for dragged types. the content view is
    /// normally the destination, but a nonactivating borderless panel can offer the drop to the window.
    @objc
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropContainer?.draggingEntered(sender) ?? []
    }

    @objc
    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropContainer?.draggingUpdated(sender) ?? []
    }

    @objc
    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dropContainer?.prepareForDragOperation(sender) ?? false
    }

    @objc
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        dropContainer?.performDragOperation(sender) ?? false
    }

    private var dropContainer: PrompterFileDropContainerView? {
        contentView as? PrompterFileDropContainerView
    }

    // MARK: - Focus

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
