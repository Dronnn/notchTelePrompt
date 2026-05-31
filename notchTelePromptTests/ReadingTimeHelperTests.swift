//
//  ReadingTimeHelperTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct ReadingTimeHelperTests {
    // MARK: - Word count

    @Test
    func wordCountCountsWhitespaceSeparatedWords() {
        #expect(ReadingTimeHelper.wordCount(in: "the quick brown fox") == 4)
    }

    @Test
    func wordCountIgnoresExtraWhitespaceAndNewlines() {
        #expect(ReadingTimeHelper.wordCount(in: "  hello   world\n\nagain  ") == 3)
    }

    @Test
    func wordCountIsZeroForEmptyOrWhitespaceOnly() {
        #expect(ReadingTimeHelper.wordCount(in: "") == 0)
        #expect(ReadingTimeHelper.wordCount(in: "   \n\t  ") == 0)
    }

    // MARK: - Character count

    @Test
    func characterCountReturnsTextLength() {
        #expect(ReadingTimeHelper.characterCount(in: "hello") == 5)
        #expect(ReadingTimeHelper.characterCount(in: "") == 0)
        #expect(ReadingTimeHelper.characterCount(in: "a b") == 3)
    }

    // MARK: - Reading time

    @Test
    func readingTimeIsZeroMinForNoWords() {
        #expect(ReadingTimeHelper.readingTime(wordCount: 0) == "0 min")
    }

    @Test
    func readingTimeIsUnderOneMinuteBelowOneMinuteOfWords() {
        // 149 words at 150 wpm is just under a minute.
        #expect(ReadingTimeHelper.readingTime(wordCount: 149) == "< 1 min")
    }

    @Test
    func readingTimeIsOneMinuteForExactlyOneMinuteOfWords() {
        #expect(ReadingTimeHelper.readingTime(wordCount: 150) == "1 min")
    }

    @Test
    func readingTimeIsTwoMinutesForTwoMinutesOfWords() {
        #expect(ReadingTimeHelper.readingTime(wordCount: 300) == "2 min")
    }

    @Test
    func readingTimeIncludesSecondsForPartialMinute() {
        // 225 words at 150 wpm is 90 seconds.
        #expect(ReadingTimeHelper.readingTime(wordCount: 225) == "1 min 30 s")
    }

    @Test
    func readingTimeDoesNotDivideByZeroWhenWpmIsZero() {
        // wpm is clamped to at least 1, so this must not crash and must produce a value.
        #expect(ReadingTimeHelper.readingTime(wordCount: 150, wpm: 0) != "0 min")
    }
}
