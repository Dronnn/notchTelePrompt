//
//  PanelDragMonitor.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@preconcurrency import AppKit

/// lets a borderless panel be moved by dragging anywhere, including over SwiftUI controls.
/// a local event monitor watches the panel's mouse events: a click is delivered normally, while
/// movement past a small threshold starts the native window-drag loop from the original mouse-down.
@MainActor
final class PanelDragMonitor {
    private weak var panel: NSPanel?
    private nonisolated(unsafe) var monitor: Any?
    private var mouseDownEvent: NSEvent?
    private var startLocation: NSPoint = .zero

    private static let threshold: CGFloat = 4
    /// the outer edge of a resizable panel stays with NSWindow so edge resizing keeps working.
    private static let resizeMargin: CGFloat = 6

    init(panel: NSPanel) {
        self.panel = panel
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { [weak self] event in
            let result = MainActor.assumeIsolated { () -> UncheckedSendable<NSEvent?> in
                guard let self else {
                    return UncheckedSendable(value: event)
                }
                return UncheckedSendable(value: self.handle(event))
            }
            return result.value
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard let panel, event.window === panel else {
            return event
        }

        switch event.type {
        case .leftMouseDown:
            guard !shouldLeaveEventToAppKit(event, panel: panel) else {
                mouseDownEvent = nil
                return event
            }
            mouseDownEvent = event
            startLocation = event.locationInWindow

        case .leftMouseDragged:
            guard let mouseDownEvent else {
                return event
            }
            let dx = event.locationInWindow.x - startLocation.x
            let dy = event.locationInWindow.y - startLocation.y
            guard dx * dx + dy * dy >= Self.threshold * Self.threshold else {
                return event
            }
            self.mouseDownEvent = nil
            panel.performDrag(with: mouseDownEvent)
            return nil

        case .leftMouseUp:
            mouseDownEvent = nil

        default:
            break
        }

        return event
    }

    /// the visible grip calls performDrag itself, and a resize edge must reach NSWindow.
    private struct UncheckedSendable<Value>: @unchecked Sendable {
        let value: Value
    }

    private func shouldLeaveEventToAppKit(_ event: NSEvent, panel: NSPanel) -> Bool {
        guard let contentView = panel.contentView else {
            return false
        }
        let point = contentView.convert(event.locationInWindow, from: nil)
        if contentView.hitTest(point) is WindowDragHandleView {
            return true
        }
        guard panel.styleMask.contains(.resizable) else {
            return false
        }
        let bounds = contentView.bounds
        return point.x < bounds.minX + Self.resizeMargin
            || point.y < bounds.minY + Self.resizeMargin
            || point.x > bounds.maxX - Self.resizeMargin
            || point.y > bounds.maxY - Self.resizeMargin
    }
}
