//
//  PrompterFileDropContainerView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// content view of the prompter panel. accepts a finder .txt / .md drop anywhere over the overlay,
/// including over the scroll-catcher and the hosting views stacked on the text. hit testing is
/// unchanged, so wheel scrolling, window drags and the hover controls keep the views they already hit.
@MainActor
final class PrompterFileDropContainerView: NSView {
    var onDropFileURL: ((URL) -> Bool)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        acceptedFileURL(from: sender) == nil ? [] : .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        acceptedFileURL(from: sender) == nil ? [] : .copy
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        acceptedFileURL(from: sender) != nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = acceptedFileURL(from: sender) else {
            return false
        }
        return onDropFileURL?(url) ?? false
    }

    /// drops `.fileURL` from descendants so the scroll-catcher and the hosting views cannot claim a
    /// finder drop. this view's own registration stays. other dragged types are left in place.
    func stripDescendantFileURLRegistrations() {
        for subview in subviews {
            Self.stripFileURLRegistrations(in: subview)
        }
    }

    static func stripFileURLRegistrations(in view: NSView) {
        if view.registeredDraggedTypes.contains(.fileURL) {
            let kept = view.registeredDraggedTypes.filter { $0 != .fileURL }
            view.unregisterDraggedTypes()
            if !kept.isEmpty {
                view.registerForDraggedTypes(kept)
            }
        }
        for subview in view.subviews {
            stripFileURLRegistrations(in: subview)
        }
    }

    private func acceptedFileURL(from sender: NSDraggingInfo) -> URL? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let objects = sender.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: options
        ) as? [NSURL]
        return objects?.first.map { $0 as URL }
    }
}
