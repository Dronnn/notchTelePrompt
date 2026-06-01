//
//  PrompterViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// holds the state the prompter overlay renders.
/// phase 7 drives currentLineIndex during playback; phase 6 just renders at it.
@MainActor
@Observable
final class PrompterViewModel {
    /// the script being shown. setting it resets the reading position to the top
    /// and refreshes the font size mirror from the script's stored settings.
    var currentScript: Script? {
        didSet {
            currentLineIndex = 0
            reloadFontSize()
        }
    }

    /// the current reading line, clamped to the valid range of lines.
    var currentLineIndex = 0 {
        didSet {
            let upperBound = max(lines.count - 1, 0)
            let clamped = min(max(currentLineIndex, 0), upperBound)
            if clamped != currentLineIndex {
                currentLineIndex = clamped
            }
        }
    }

    /// the per-script prompter font size in points, mirrored from the current script's settings
    /// (falling back to the default). the view layer binds to this instead of reading the @Model.
    private(set) var fontSize = PrompterFontSize.default

    /// the script text split into renderable lines. memoized so it resplits only when the text
    /// actually changes (not every render or scroll tick), while still reflecting live edits.
    var lines: [String] {
        let text = currentScript?.text ?? ""
        if cachedText != text {
            cachedText = text
            cachedLines = PrompterTextSplitter.lines(from: text)
        }
        return cachedLines
    }

    @ObservationIgnored private var cachedText: String?
    @ObservationIgnored private var cachedLines: [String] = []

    /// persists font-size changes; injected so the overlay writes through the same store as the editor.
    @ObservationIgnored private let store: ScriptStore?
    @ObservationIgnored private var fontSizeObserver: NotificationObserverToken?

    init(store: ScriptStore? = nil) {
        self.store = store
        observeFontSizeChanges()
    }

    /// reading progress in [0, 1] for the current line within the script.
    var progress: Double {
        PrompterLineEmphasis.progress(currentIndex: currentLineIndex, lineCount: lines.count)
    }

    // MARK: - Font size

    func increaseFontSize() {
        applyFontSize(PrompterFontSize.incremented(fontSize))
    }

    func decreaseFontSize() {
        applyFontSize(PrompterFontSize.decremented(fontSize))
    }

    /// clamps, mirrors, persists through the store and broadcasts so the editor stays in sync.
    private func applyFontSize(_ newValue: Double) {
        guard let script = currentScript else {
            return
        }
        let clamped = PrompterFontSize.clamp(newValue)
        guard clamped != fontSize else {
            return
        }
        fontSize = clamped
        try? store?.setFontSize(clamped, on: script)
        NotificationCenter.default.post(
            name: .scriptFontSizeDidChange,
            object: nil,
            userInfo: [ScriptFontSizeChange.scriptIDKey: script.id]
        )
    }

    /// refreshes the mirror from the current script's stored settings, defaulting when none exist.
    private func reloadFontSize() {
        fontSize = PrompterFontSize.clamp(currentScript?.settingsBlob?.fontSize ?? PrompterFontSize.default)
    }

    /// re-reads the size when another surface (the editor) changes it for the script we are showing.
    private func observeFontSizeChanges() {
        fontSizeObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .scriptFontSizeDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let changedID = notification.userInfo?[ScriptFontSizeChange.scriptIDKey] as? UUID
            Task { @MainActor in
                guard let self, let changedID, self.currentScript?.id == changedID else {
                    return
                }
                self.reloadFontSize()
            }
        })
    }
}
