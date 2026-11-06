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
}
