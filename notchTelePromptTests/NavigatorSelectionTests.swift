//
//  NavigatorSelectionTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

struct NavigatorSelectionTests {
    // MARK: - Next

    @Test
    func nextAdvancesWithinRange() {
        #expect(NavigatorSelection.nextIndex(after: 0, count: 3) == 1)
        #expect(NavigatorSelection.nextIndex(after: 1, count: 3) == 2)
    }

    @Test
    func nextClampsAtEnd() {
        #expect(NavigatorSelection.nextIndex(after: 2, count: 3) == 2)
    }

    @Test
    func nextFromNoSelectionGoesToFirst() {
        #expect(NavigatorSelection.nextIndex(after: nil, count: 3) == 0)
    }

    @Test
    func nextOnEmptyListIsNil() {
        #expect(NavigatorSelection.nextIndex(after: nil, count: 0) == nil)
        #expect(NavigatorSelection.nextIndex(after: 0, count: 0) == nil)
    }

    // MARK: - Previous

    @Test
    func previousMovesBackWithinRange() {
        #expect(NavigatorSelection.previousIndex(before: 2, count: 3) == 1)
        #expect(NavigatorSelection.previousIndex(before: 1, count: 3) == 0)
    }

    @Test
    func previousClampsAtStart() {
        #expect(NavigatorSelection.previousIndex(before: 0, count: 3) == 0)
    }

    @Test
    func previousFromNoSelectionGoesToFirst() {
        #expect(NavigatorSelection.previousIndex(before: nil, count: 3) == 0)
    }

    @Test
    func previousOnEmptyListIsNil() {
        #expect(NavigatorSelection.previousIndex(before: nil, count: 0) == nil)
        #expect(NavigatorSelection.previousIndex(before: 0, count: 0) == nil)
    }
}
