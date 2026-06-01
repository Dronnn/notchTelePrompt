//
//  ScrollSpeed.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics

/// the auto-scroll speed, stored as points-per-second (the unit the engine integrates directly).
/// provides documented conversions to/from words-per-minute so the UI and per-script settings can
/// speak WPM while the engine stays in points. pure value type, nonisolated and testable.
nonisolated struct ScrollSpeed: Equatable {
    /// the primary unit: how many points the content scrolls per second.
    var pointsPerSecond: Double

    init(pointsPerSecond: Double) {
        self.pointsPerSecond = pointsPerSecond
    }

    // MARK: - WPM conversion

    /// an average prompter line is short; we assume this many words occupy one rendered line.
    /// it lets us turn a reading rate (words/minute) into a scroll rate (points/second):
    ///   pointsPerLine  = fontSize + lineSpacing            (vertical travel to advance one line)
    ///   pointsPerWord  = pointsPerLine / wordsPerLine
    ///   pointsPerSecond = wpm * pointsPerWord / 60
    /// the constant only sets how WPM maps to points; the engine never depends on it once a
    /// points/second value is chosen, so an imperfect estimate just shifts the WPM scale slightly.
    private static let assumedWordsPerLine = 7.0

    /// points scrolled per word for the given line geometry.
    private static func pointsPerWord(fontSize: Double, lineSpacing: Double) -> Double {
        let pointsPerLine = fontSize + lineSpacing
        return pointsPerLine / assumedWordsPerLine
    }

    /// builds a speed from a reading rate in words-per-minute for the given line geometry.
    init(wordsPerMinute: Double, fontSize: Double, lineSpacing: Double) {
        let perWord = Self.pointsPerWord(fontSize: fontSize, lineSpacing: lineSpacing)
        self.init(pointsPerSecond: wordsPerMinute * perWord / 60)
    }

    /// the equivalent reading rate in words-per-minute for the given line geometry.
    func wordsPerMinute(fontSize: Double, lineSpacing: Double) -> Double {
        let perWord = Self.pointsPerWord(fontSize: fontSize, lineSpacing: lineSpacing)
        guard perWord > 0 else {
            return 0
        }
        return pointsPerSecond * 60 / perWord
    }

    // MARK: - Defaults & clamping

    /// the default reading rate in words-per-minute (spec §27 recommends ~130-160; ScriptPrompterSettings
    /// stores 150 as its default scrollSpeed). callers pair it with the current font/line geometry.
    static let defaultWordsPerMinute = 150.0

    /// sane bounds in words-per-minute to keep custom rates usable.
    static let minWordsPerMinute = 40.0
    static let maxWordsPerMinute = 400.0

    /// the default speed for the given line geometry.
    static func `default`(fontSize: Double, lineSpacing: Double) -> ScrollSpeed {
        ScrollSpeed(wordsPerMinute: defaultWordsPerMinute, fontSize: fontSize, lineSpacing: lineSpacing)
    }

    /// constrains the speed to the WPM bounds expressed in points for the given line geometry.
    func clamped(fontSize: Double, lineSpacing: Double) -> ScrollSpeed {
        let lower = ScrollSpeed(wordsPerMinute: Self.minWordsPerMinute, fontSize: fontSize, lineSpacing: lineSpacing)
        let upper = ScrollSpeed(wordsPerMinute: Self.maxWordsPerMinute, fontSize: fontSize, lineSpacing: lineSpacing)
        let value = Swift.min(Swift.max(pointsPerSecond, lower.pointsPerSecond), upper.pointsPerSecond)
        return ScrollSpeed(pointsPerSecond: value)
    }
}
