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
    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }
}
