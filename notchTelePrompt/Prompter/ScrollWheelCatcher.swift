//
//  ScrollWheelCatcher.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// a transparent overlay that forwards mouse-wheel / trackpad scroll into the prompter as manual
/// nudges. SwiftUI has no scroll-wheel hook for a non-scrolling container, so we drop down to AppKit.
///
/// note: arrow-key scroll is intentionally out of scope here. the prompter panel is non-activating /
/// non-key, so it cannot receive key events; arrow / hotkey scrolling lands via global hotkeys in
/// phase 8 instead.
struct ScrollWheelCatcher: NSViewRepresentable {
    /// called with the delta to apply to the scroll offset (positive scrolls the content down).
    let onScroll: (Double) -> Void

    func makeNSView(context _: Context) -> ScrollWheelCatchingView {
        let view = ScrollWheelCatchingView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollWheelCatchingView, context _: Context) {
        nsView.onScroll = onScroll
    }
}

/// the backing AppKit view that captures `scrollWheel(with:)`.
final class ScrollWheelCatchingView: NSView {
    var onScroll: ((Double) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        // scrolling up (content moves down) gives a positive scrollingDeltaY; invert so a natural
        // upward gesture advances the prompter (increases the offset).
        onScroll?(-event.scrollingDeltaY)
    }

    /// keep hitTest's default so scroll events still route here, but forward mouse clicks/drags to the
    /// responder chain so the controls stay tappable and window-background dragging still works.
    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        nextResponder?.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
    }
}
