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

/// moves the hosting window while the user drags. attaching this to a panel's root view lets the
/// user grab any area that doesn't have its own drag gesture; child gestures such as list reordering
/// keep priority, and clicks still reach buttons because the drag needs a few points of movement.
private struct WindowDragGestureModifier: ViewModifier {
    @State private var window: NSWindow?
    @State private var initialOrigin: NSPoint?

    func body(content: Content) -> some View {
        content
            .background(WindowReader { window = $0 })
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .global)
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

extension View {
    func windowDragGesture() -> some View {
        modifier(WindowDragGestureModifier())
    }
}

/// reports the hosting window once the view is attached to it.
private struct WindowReader: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context _: Context) -> WindowReaderView {
        let view = WindowReaderView()
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ nsView: WindowReaderView, context _: Context) {
        nsView.onWindow = onWindow
    }
}

private final class WindowReaderView: NSView {
    var onWindow: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            onWindow?(window)
        }
    }
}
