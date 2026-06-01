//
//  ScriptTextCoreTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct ScriptTextCoreTests {
    // MARK: - Decoding

    @Test
    func decodeUTF8ReturnsString() {
        let original = "Hello, мир — 世界\nsecond line"
        let data = Data(original.utf8)
        #expect(ScriptTextCore.decodeText(from: data) == original)
    }

    @Test
    func decodeNonUTF8ReturnsNil() {
        let data = Data([0xFF, 0xFE])
        #expect(ScriptTextCore.decodeText(from: data) == nil)
    }

    // MARK: - Line breaks

    @Test
    func normalizePreservesUnixLineBreaks() {
        #expect(ScriptTextCore.normalizeLineBreaks("a\nb\nc") == "a\nb\nc")
    }

    @Test
    func normalizeCRLFtoLF() {
        #expect(ScriptTextCore.normalizeLineBreaks("a\r\nb\r\nc") == "a\nb\nc")
    }

    @Test
    func normalizeMixedLineBreaks() {
        #expect(ScriptTextCore.normalizeLineBreaks("a\r\nb\nc\rd") == "a\nb\nc\nd")
    }

    // MARK: - Title

    @Test
    func titleFromFirstNonEmptyLine() {
        #expect(ScriptTextCore.title(forFirstLineOf: "  \nHello World\nSecond") == "Hello World")
    }

    @Test
    func titleTruncatesLongFirstLine() {
        let longLine = String(repeating: "x", count: 70)
        let title = ScriptTextCore.title(forFirstLineOf: longLine)
        #expect(title.count == ScriptTextCore.maxTitleLength + 1)
        #expect(title.hasSuffix("…"))
    }

    @Test
    func titleFallsBackToDateWhenTextEmpty() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let title = ScriptTextCore.title(forFirstLineOf: "", fallbackDate: date)
        #expect(!title.isEmpty)
        let year = date.formatted(.dateTime.year())
        #expect(title.contains(year))
    }

    @Test
    func titleFallsBackToDateWhenAllLinesBlank() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let title = ScriptTextCore.title(forFirstLineOf: "  \n  \n", fallbackDate: date)
        #expect(!title.isEmpty)
        #expect(title.contains(date.formatted(.dateTime.year())))
    }

    // MARK: - File data round-trip

    @Test
    func fileDataRoundTrip_txt() {
        let text = "line one\nline two\n"
        let data = ScriptTextCore.fileData(for: text, format: .txt)
        #expect(ScriptTextCore.decodeText(from: data) == text)
    }

    @Test
    func fileDataRoundTrip_md() {
        let text = "# Heading\n\nbody paragraph"
        let data = ScriptTextCore.fileData(for: text, format: .md)
        #expect(ScriptTextCore.decodeText(from: data) == text)
    }

    @Test
    func fileDataForEmptyTextIsEmpty() {
        #expect(ScriptTextCore.fileData(for: "", format: .txt).isEmpty)
    }
}
