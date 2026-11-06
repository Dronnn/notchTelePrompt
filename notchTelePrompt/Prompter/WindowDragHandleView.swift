//
//  WindowDragHandleView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// a visible drag target that remains usable above the hosting and scroll-catching views.
final class WindowDragHandleView: NSView {
    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func draw(_: NSRect) {
        NSColor.white.withAlphaComponent(0.65).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 7, dy: 5), xRadius: 2, yRadius: 2).fill()
    }
}

/// places the AppKit drag grip inside SwiftUI-hosted panels so their content can be moved even
/// when the hosting view swallows background clicks.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context _: Context) -> WindowDragHandleView {
        WindowDragHandleView()
    }

    func updateNSView(_: WindowDragHandleView, context _: Context) {}
}
