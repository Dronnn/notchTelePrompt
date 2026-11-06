//
//  FileDropContainerView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// wraps the main window's SwiftUI content and accepts Finder file drops over the whole window,
/// including the library and sets sidebars. The editor keeps its own drop handling for the
/// new-vs-replace choice; this layer imports a dropped file as a new script.
@MainActor
final class FileDropContainerView: NSView {
    var onDropFileURL: ((URL) -> Bool)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard firstFileURL(from: sender) != nil else {
            return []
        }
        setDropHighlight(true)
        return .copy
    }

    override func draggingExited(_: NSDraggingInfo?) {
        setDropHighlight(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        firstFileURL(from: sender) != nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer { setDropHighlight(false) }
        guard let url = firstFileURL(from: sender) else {
            return false
        }
        return onDropFileURL?(url) ?? false
    }

    private func firstFileURL(from sender: NSDraggingInfo) -> URL? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let objects = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: options
        ) as? [NSURL]
        return objects?.first.map { $0 as URL }
    }

    private func setDropHighlight(_ highlighted: Bool) {
        layer?.borderWidth = highlighted ? 3 : 0
        layer?.borderColor = highlighted ? NSColor.controlAccentColor.cgColor : nil
        layer?.cornerRadius = highlighted ? 8 : 0
    }
}
