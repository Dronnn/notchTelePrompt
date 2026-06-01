//
//  ScrollSpeedTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

struct ScrollSpeedTests {
    private let fontSize = 28.0
    private let lineSpacing = 8.0

    // MARK: - Round trip

    @Test
    func wpmRoundTripsThroughPointsPerSecond() {
        for wpm in [60.0, 130.0, 150.0, 200.0, 300.0] {
            let speed = ScrollSpeed(wordsPerMinute: wpm, fontSize: fontSize, lineSpacing: lineSpacing)
            let recovered = speed.wordsPerMinute(fontSize: fontSize, lineSpacing: lineSpacing)
            #expect(abs(recovered - wpm) < 0.0001)
        }
    }

    @Test
    func higherWpmMeansFasterPoints() {
        let slow = ScrollSpeed(wordsPerMinute: 100, fontSize: fontSize, lineSpacing: lineSpacing)
        let fast = ScrollSpeed(wordsPerMinute: 200, fontSize: fontSize, lineSpacing: lineSpacing)
        #expect(fast.pointsPerSecond > slow.pointsPerSecond)
    }

    @Test
    func largerFontScrollsMorePointsForTheSameWpm() {
        // a bigger line box means more points must travel to read the same number of words.
        let small = ScrollSpeed(wordsPerMinute: 150, fontSize: 20, lineSpacing: lineSpacing)
        let large = ScrollSpeed(wordsPerMinute: 150, fontSize: 60, lineSpacing: lineSpacing)
        #expect(large.pointsPerSecond > small.pointsPerSecond)
    }

    // MARK: - Defaults

    @Test
    func defaultUsesTheSpecWordsPerMinute() {
        #expect(ScrollSpeed.defaultWordsPerMinute == 150)
        let speed = ScrollSpeed.default(fontSize: fontSize, lineSpacing: lineSpacing)
        let wpm = speed.wordsPerMinute(fontSize: fontSize, lineSpacing: lineSpacing)
        #expect(abs(wpm - 150) < 0.0001)
    }

    // MARK: - Clamping

    @Test
    func clampPinsToMinWpm() {
        let tooSlow = ScrollSpeed(wordsPerMinute: 1, fontSize: fontSize, lineSpacing: lineSpacing)
        let clamped = tooSlow.clamped(fontSize: fontSize, lineSpacing: lineSpacing)
        let wpm = clamped.wordsPerMinute(fontSize: fontSize, lineSpacing: lineSpacing)
        #expect(abs(wpm - ScrollSpeed.minWordsPerMinute) < 0.0001)
    }

    @Test
    func clampPinsToMaxWpm() {
        let tooFast = ScrollSpeed(wordsPerMinute: 10_000, fontSize: fontSize, lineSpacing: lineSpacing)
        let clamped = tooFast.clamped(fontSize: fontSize, lineSpacing: lineSpacing)
        let wpm = clamped.wordsPerMinute(fontSize: fontSize, lineSpacing: lineSpacing)
        #expect(abs(wpm - ScrollSpeed.maxWordsPerMinute) < 0.0001)
    }

    @Test
    func clampLeavesInRangeSpeedsUntouched() {
        let inRange = ScrollSpeed(wordsPerMinute: 150, fontSize: fontSize, lineSpacing: lineSpacing)
        let clamped = inRange.clamped(fontSize: fontSize, lineSpacing: lineSpacing)
        #expect(abs(clamped.pointsPerSecond - inRange.pointsPerSecond) < 0.0001)
    }
}
