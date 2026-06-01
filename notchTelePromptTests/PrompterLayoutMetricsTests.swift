//
//  PrompterLayoutMetricsTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

struct PrompterLayoutMetricsTests {
    private let fontSize = 20.0
    private let lineSpacing = 10.0
    // lineHeight = 30 for the values above.

    // MARK: - Content height

    @Test
    func contentHeightIsZeroForNoLines() {
        #expect(PrompterLayoutMetrics.contentHeight(lineCount: 0, fontSize: fontSize, lineSpacing: lineSpacing) == 0)
    }

    @Test
    func contentHeightOfOneLineIsJustTheFontBox() {
        #expect(PrompterLayoutMetrics.contentHeight(lineCount: 1, fontSize: fontSize, lineSpacing: lineSpacing)
            == fontSize)
    }

    @Test
    func contentHeightAddsLineBoxesAndGaps() {
        // 3 lines: 3 * 20 + 2 * 10 = 80
        #expect(PrompterLayoutMetrics.contentHeight(lineCount: 3, fontSize: fontSize, lineSpacing: lineSpacing) == 80)
    }

    // MARK: - Max offset (with breathing room)

    @Test
    func maxOffsetIsZeroForEmptyOrSingleLine() {
        let emptyHeight = PrompterLayoutMetrics.contentHeight(
            lineCount: 0,
            fontSize: fontSize,
            lineSpacing: lineSpacing
        )
        let oneHeight = PrompterLayoutMetrics.contentHeight(lineCount: 1, fontSize: fontSize, lineSpacing: lineSpacing)
        #expect(PrompterLayoutMetrics.maxOffset(
            contentHeight: emptyHeight, viewportHeight: 100, fontSize: fontSize, lineSpacing: lineSpacing
        ) == 0)
        #expect(PrompterLayoutMetrics.maxOffset(
            contentHeight: oneHeight, viewportHeight: 100, fontSize: fontSize, lineSpacing: lineSpacing
        ) == 0)
    }

    @Test
    func maxOffsetIsTheFirstToLastLineCenterSpan() {
        // 3 lines, lineHeight 30 -> span from line 0 centered to line 2 centered = 2 * 30 = 60.
        let height = PrompterLayoutMetrics.contentHeight(lineCount: 3, fontSize: fontSize, lineSpacing: lineSpacing)
        let maxOffset = PrompterLayoutMetrics.maxOffset(
            contentHeight: height, viewportHeight: 100, fontSize: fontSize, lineSpacing: lineSpacing
        )
        #expect(maxOffset == 60)
    }

    @Test
    func maxOffsetIsIndependentOfViewportHeight() {
        let height = PrompterLayoutMetrics.contentHeight(lineCount: 5, fontSize: fontSize, lineSpacing: lineSpacing)
        let small = PrompterLayoutMetrics.maxOffset(
            contentHeight: height, viewportHeight: 10, fontSize: fontSize, lineSpacing: lineSpacing
        )
        let large = PrompterLayoutMetrics.maxOffset(
            contentHeight: height, viewportHeight: 999, fontSize: fontSize, lineSpacing: lineSpacing
        )
        #expect(small == large)
    }

    // MARK: - Offset <-> line index round trip

    @Test
    func offsetForLineIndexCentersEachLine() {
        let maxOffset = 120.0 // 5 lines: 4 * 30
        #expect(PrompterLayoutMetrics.offset(
            forLineIndex: 0, fontSize: fontSize, lineSpacing: lineSpacing, maxOffset: maxOffset
        ) == 0)
        #expect(PrompterLayoutMetrics.offset(
            forLineIndex: 2, fontSize: fontSize, lineSpacing: lineSpacing, maxOffset: maxOffset
        ) == 60)
    }

    @Test
    func offsetForLineIndexClampsToMax() {
        let maxOffset = 60.0 // only 3 lines worth
        #expect(PrompterLayoutMetrics.offset(
            forLineIndex: 99, fontSize: fontSize, lineSpacing: lineSpacing, maxOffset: maxOffset
        ) == 60)
    }

    @Test
    func lineIndexForOffsetRoundTrips() {
        for index in 0 ..< 5 {
            let offset = PrompterLayoutMetrics.offset(
                forLineIndex: index, fontSize: fontSize, lineSpacing: lineSpacing, maxOffset: 120
            )
            let recovered = PrompterLayoutMetrics.lineIndex(
                forOffset: offset, lineCount: 5, fontSize: fontSize, lineSpacing: lineSpacing
            )
            #expect(recovered == index)
        }
    }

    @Test
    func lineIndexRoundsToNearestLine() {
        // halfway between line 1 (offset 30) and line 2 (offset 60) is 45 -> rounds to line 2.
        let index = PrompterLayoutMetrics.lineIndex(
            forOffset: 45, lineCount: 5, fontSize: fontSize, lineSpacing: lineSpacing
        )
        #expect(index == 2)
    }

    @Test
    func lineIndexClampsToValidRange() {
        #expect(PrompterLayoutMetrics.lineIndex(
            forOffset: 9_999, lineCount: 3, fontSize: fontSize, lineSpacing: lineSpacing
        ) == 2)
        #expect(PrompterLayoutMetrics.lineIndex(
            forOffset: -50, lineCount: 3, fontSize: fontSize, lineSpacing: lineSpacing
        ) == 0)
    }

    @Test
    func lineIndexIsZeroForEmptyScript() {
        #expect(PrompterLayoutMetrics.lineIndex(
            forOffset: 100, lineCount: 0, fontSize: fontSize, lineSpacing: lineSpacing
        ) == 0)
    }
}
