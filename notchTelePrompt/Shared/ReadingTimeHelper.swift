//
//  ReadingTimeHelper.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// derives word/character counts and an estimated reading time from script text.
/// pure and stateless, so it is usable from any isolation context.
nonisolated enum ReadingTimeHelper {
    /// number of whitespace-separated words, ignoring empty fragments.
    static func wordCount(in text: String) -> Int {
        text
            .split { $0.isWhitespace || $0.isNewline }
            .count
    }

    /// total character count, including whitespace.
    static func characterCount(in text: String) -> Int {
        text.count
    }

    /// human-readable reading time estimate for a word count at the given words-per-minute.
    static func readingTime(wordCount: Int, wpm: Int = 150) -> String {
        guard wordCount > 0 else {
            return "0 min"
        }
        let totalSeconds = Int(Double(wordCount) / Double(max(wpm, 1)) * 60)
        guard totalSeconds >= 60 else {
            return "< 1 min"
        }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if seconds == 0 {
            return "\(minutes) min"
        }
        return "\(minutes) min \(seconds) s"
    }
}
