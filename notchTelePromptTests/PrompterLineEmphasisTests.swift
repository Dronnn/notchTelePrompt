//
//  PrompterLineEmphasisTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct PrompterLineEmphasisTests {
    // MARK: - Opacity

    @Test
    func currentLineIsFullyOpaque() {
        #expect(PrompterLineEmphasis.opacity(distanceFromCurrent: 0) == 1.0)
    }

    @Test
    func adjacentLinesAreSlightlyDimmed() {
        #expect(PrompterLineEmphasis.opacity(distanceFromCurrent: 1) == 0.65)
        #expect(PrompterLineEmphasis.opacity(distanceFromCurrent: -1) == 0.65)
    }

    @Test
    func twoAwayLinesAreDimmerStill() {
        #expect(PrompterLineEmphasis.opacity(distanceFromCurrent: 2) == 0.5)
        #expect(PrompterLineEmphasis.opacity(distanceFromCurrent: -2) == 0.5)
    }

    @Test
    func farLinesHitTheOpacityFloor() {
        #expect(PrompterLineEmphasis.opacity(distanceFromCurrent: 5) == 0.4)
        #expect(PrompterLineEmphasis.opacity(distanceFromCurrent: -5) == 0.4)
    }

    // MARK: - Current line flag

    @Test
    func isCurrentOnlyAtDistanceZero() {
        #expect(PrompterLineEmphasis.isCurrent(0))
        #expect(!PrompterLineEmphasis.isCurrent(1))
        #expect(!PrompterLineEmphasis.isCurrent(-1))
    }

    // MARK: - Progress

    @Test
    func progressIsZeroForEmptyOrSingleLine() {
        #expect(PrompterLineEmphasis.progress(currentIndex: 0, lineCount: 0) == 0)
        #expect(PrompterLineEmphasis.progress(currentIndex: 0, lineCount: 1) == 0)
    }

    @Test
    func progressIsOneAtLastLine() {
        #expect(PrompterLineEmphasis.progress(currentIndex: 9, lineCount: 10) == 1.0)
    }

    @Test
    func progressIsTheExpectedRatioInTheMiddle() {
        #expect(PrompterLineEmphasis.progress(currentIndex: 2, lineCount: 5) == 0.5)
    }

    @Test
    func progressClampsOutOfRangeIndices() {
        #expect(PrompterLineEmphasis.progress(currentIndex: -3, lineCount: 5) == 0)
        #expect(PrompterLineEmphasis.progress(currentIndex: 99, lineCount: 5) == 1.0)
    }
}
