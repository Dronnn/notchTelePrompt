//
//  PrompterTextSplitterTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct PrompterTextSplitterTests {
    // MARK: - Empty input

    @Test
    func emptyStringReturnsEmptyArray() {
        #expect(PrompterTextSplitter.lines(from: "").isEmpty)
    }

    // MARK: - Paragraph preservation

    @Test
    func preservesEmptyLinesBetweenParagraphs() {
        #expect(PrompterTextSplitter.lines(from: "a\n\nb") == ["a", "", "b"])
    }

    // MARK: - Newline normalization

    @Test
    func normalizesCarriageReturnLineFeed() {
        #expect(PrompterTextSplitter.lines(from: "a\r\nb") == ["a", "b"])
    }

    @Test
    func normalizesLoneCarriageReturn() {
        #expect(PrompterTextSplitter.lines(from: "a\rb") == ["a", "b"])
    }

    // MARK: - Single line and trailing newline

    @Test
    func singleLineReturnsOneEntry() {
        #expect(PrompterTextSplitter.lines(from: "hello") == ["hello"])
    }

    @Test
    func trailingNewlineYieldsTrailingEmptyLine() {
        // a trailing "\n" is kept as a final empty line, matching components(separatedBy:).
        #expect(PrompterTextSplitter.lines(from: "a\n") == ["a", ""])
    }
}
