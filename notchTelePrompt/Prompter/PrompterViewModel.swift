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
    /// the script being shown. setting it resets the reading position to the top.
    var currentScript: Script? {
        didSet { currentLineIndex = 0 }
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

    /// reading progress in [0, 1] for the current line within the script.
    var progress: Double {
        PrompterLineEmphasis.progress(currentIndex: currentLineIndex, lineCount: lines.count)
    }
}
