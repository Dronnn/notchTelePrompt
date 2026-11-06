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

/// a transparent hit-testing layer placed behind panel content. dragging empty areas moves the
/// hosting window, while interactive rows and buttons above it keep receiving their own clicks.
struct WindowDragArea: View {
    @State private var window: NSWindow?
    @State private var initialOrigin: NSPoint?

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .background(WindowAccessor { window = $0 })
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        guard let window else { return }
                        if initialOrigin == nil {
                            initialOrigin = window.frame.origin
                        }
                        guard let initialOrigin else { return }
                        // SwiftUI's global y grows downward; window origins grow upward.
                        window.setFrameOrigin(NSPoint(
                            x: initialOrigin.x + value.translation.width,
                            y: initialOrigin.y - value.translation.height
                        ))
                    }
                    .onEnded { _ in initialOrigin = nil }
            )
    }
}

/// exposes the hosting window to SwiftUI without changing the view hierarchy.
private struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context _: Context) -> WindowAccessorView {
        let view = WindowAccessorView()
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ nsView: WindowAccessorView, context _: Context) {
        nsView.onWindow = onWindow
        onWindow(nsView.window)
    }
}

private final class WindowAccessorView: NSView {
    var onWindow: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindow?(window)
    }
}
