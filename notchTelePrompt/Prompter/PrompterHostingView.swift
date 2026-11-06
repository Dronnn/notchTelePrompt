//
//  PrompterHostingView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// hosting view for the prompter overlay that accepts the first click on a non-activating panel.
/// without this the close / snap buttons would only react after a second click that first focuses the panel.
final class PrompterHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool {
        true
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }

    override func layout() {
        super.layout()
        // swiftui may register a new scroll-catcher for file urls when the text is rebuilt.
        // the overlay container is the drop target, so this host must not keep that registration.
        PrompterFileDropContainerView.stripFileURLRegistrations(in: self)
    }

    // MARK: - File drop forwarding

    /// the hosting view can be the destination for a finder drop even when the content view is
    /// registered. forward file drops to the prompter's container; leave other drags to SwiftUI.
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        fileDropContainer?.draggingEntered(sender) ?? super.draggingEntered(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        fileDropContainer?.draggingUpdated(sender) ?? super.draggingUpdated(sender)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        if let fileDropContainer {
            fileDropContainer.draggingExited(sender)
        } else {
            super.draggingExited(sender)
        }
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        fileDropContainer?.prepareForDragOperation(sender) ?? super.prepareForDragOperation(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        fileDropContainer?.performDragOperation(sender) ?? super.performDragOperation(sender)
    }

    private var fileDropContainer: PrompterFileDropContainerView? {
        var view = superview
        while let current = view {
            if let container = current as? PrompterFileDropContainerView {
                return container
            }
            view = current.superview
        }
        return nil
    }
}
