//
//  PrompterFontSizeTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

struct PrompterFontSizeTests {
    // MARK: - Clamp

    @Test
    func clampPinsBelowMinToMin() {
        #expect(PrompterFontSize.clamp(PrompterFontSize.min - 10) == PrompterFontSize.min)
        #expect(PrompterFontSize.clamp(0) == PrompterFontSize.min)
    }

    @Test
    func clampPinsAboveMaxToMax() {
        #expect(PrompterFontSize.clamp(PrompterFontSize.max + 10) == PrompterFontSize.max)
        #expect(PrompterFontSize.clamp(1_000) == PrompterFontSize.max)
    }

    @Test
    func clampLeavesInRangeValuesUntouched() {
        #expect(PrompterFontSize.clamp(PrompterFontSize.min) == PrompterFontSize.min)
        #expect(PrompterFontSize.clamp(PrompterFontSize.max) == PrompterFontSize.max)
        #expect(PrompterFontSize.clamp(PrompterFontSize.default) == PrompterFontSize.default)
    }

    // MARK: - Increment / decrement

    @Test
    func incrementAddsOneStep() {
        #expect(PrompterFontSize.incremented(PrompterFontSize.default)
            == PrompterFontSize.default + PrompterFontSize.step)
    }

    @Test
    func decrementSubtractsOneStep() {
        #expect(PrompterFontSize.decremented(PrompterFontSize.default)
            == PrompterFontSize.default - PrompterFontSize.step)
    }

    @Test
    func incrementAtMaxStaysAtMax() {
        #expect(PrompterFontSize.incremented(PrompterFontSize.max) == PrompterFontSize.max)
    }

    @Test
    func decrementAtMinStaysAtMin() {
        #expect(PrompterFontSize.decremented(PrompterFontSize.min) == PrompterFontSize.min)
    }

    @Test
    func incrementNearMaxClampsToMax() {
        #expect(PrompterFontSize.incremented(PrompterFontSize.max - 1) == PrompterFontSize.max)
    }

    @Test
    func decrementNearMinClampsToMin() {
        #expect(PrompterFontSize.decremented(PrompterFontSize.min + 1) == PrompterFontSize.min)
    }
}
