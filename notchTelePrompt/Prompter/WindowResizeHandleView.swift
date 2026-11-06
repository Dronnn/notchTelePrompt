//
//  WindowResizeHandleView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// a bottom-right resize grip for the borderless prompter.
final class WindowResizeHandleView: NSView {
    var onResizeEnd: (() -> Void)?
    private var initialFrame: CGRect?
    private var initialMouseLocation = CGPoint.zero

    override var mouseDownCanMoveWindow: Bool {
        false
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        true
    }

    override func resetCursorRects() {
        if #available(macOS 15.0, *) {
            addCursorRect(bounds, cursor: .frameResize(position: .bottomRight, directions: .all))
        } else {
            addCursorRect(bounds, cursor: .crosshair)
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        initialFrame = window.frame
        initialMouseLocation = window.convertPoint(toScreen: event.locationInWindow)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let initialFrame else { return }
        let location = window.convertPoint(toScreen: event.locationInWindow)
        var size = CGSize(
            width: max(window.minSize.width, initialFrame.width + location.x - initialMouseLocation.x),
            height: max(window.minSize.height, initialFrame.height - location.y + initialMouseLocation.y)
        )
        if let visibleFrame = window.screen?.visibleFrame {
            size.width = min(size.width, max(window.minSize.width, visibleFrame.maxX - initialFrame.minX))
            size.height = min(size.height, max(window.minSize.height, initialFrame.maxY - visibleFrame.minY))
        }
        window.setFrame(
            CGRect(x: initialFrame.minX, y: initialFrame.maxY - size.height, width: size.width, height: size.height),
            display: true
        )
    }

    override func mouseUp(with _: NSEvent) {
        initialFrame = nil
        onResizeEnd?()
    }

    override func draw(_: NSRect) {
        NSColor.white.withAlphaComponent(0.7).setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.5
        for inset in [CGFloat(5), 10, 15] {
            path.move(to: CGPoint(x: bounds.maxX - inset, y: bounds.minY + 4))
            path.line(to: CGPoint(x: bounds.maxX - 4, y: bounds.minY + inset))
        }
        path.stroke()
    }
}
