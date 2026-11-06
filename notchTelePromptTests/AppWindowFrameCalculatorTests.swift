//
//  AppWindowFrameCalculatorTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import CoreGraphics
@testable import notchTelePrompt
import Testing

struct AppWindowFrameCalculatorTests {
    private let screen = CGRect(x: 0, y: 0, width: 1_512, height: 945)

    @Test
    func clearPreferredFrameDoesNotMove() {
        let preferred = CGRect(x: 450, y: 300, width: 460, height: 380)
        let occupied = CGRect(x: 0, y: 0, width: 260, height: 360)
        #expect(AppWindowFrameCalculator.frame(preferred: preferred, visibleFrame: screen, avoiding: [occupied])
            == preferred)
    }

    @Test
    func overlappingWindowMovesBesideExistingWindows() {
        let occupied = CGRect(x: 0, y: 200, width: 900, height: 600)
        let preferred = CGRect(x: 500, y: 300, width: 460, height: 380)
        let frame = AppWindowFrameCalculator.frame(preferred: preferred, visibleFrame: screen, avoiding: [occupied])
        #expect(!frame.intersects(occupied))
        #expect(screen.contains(frame))
    }

    @Test
    func prompterAndNavigatorBothRemainClear() {
        let occupied = [
            CGRect(x: 430, y: 810, width: 650, height: 130),
            CGRect(x: 0, y: 250, width: 260, height: 360)
        ]
        let frame = AppWindowFrameCalculator.frame(
            preferred: CGRect(x: 430, y: 700, width: 460, height: 380),
            visibleFrame: screen,
            avoiding: occupied
        )
        #expect(occupied.allSatisfy { !frame.intersects($0) })
        #expect(screen.contains(frame))
    }

    @Test
    func negativeScreenOriginKeepsTheWholeFrameVisible() {
        let visible = CGRect(x: -1_440, y: 100, width: 1_440, height: 850)
        let frame = AppWindowFrameCalculator.frame(
            preferred: CGRect(x: -100, y: 800, width: 460, height: 380),
            visibleFrame: visible,
            avoiding: []
        )
        #expect(visible.contains(frame))
    }

    @Test
    func crowdedScreenStillKeepsTitleBarAndWindowOnScreen() {
        let visible = CGRect(x: 0, y: 0, width: 700, height: 500)
        let frame = AppWindowFrameCalculator.frame(
            preferred: CGRect(x: 300, y: 400, width: 460, height: 380),
            visibleFrame: visible,
            avoiding: [visible]
        )
        #expect(visible.contains(frame))
        #expect(frame.size == CGSize(width: 460, height: 380))
    }

    @Test
    func oversizedWindowIsCappedToScreen() {
        let frame = AppWindowFrameCalculator.frame(
            preferred: CGRect(x: -300, y: 600, width: 2_000, height: 1_200),
            visibleFrame: screen,
            avoiding: []
        )
        #expect(frame == screen)
    }

    @Test
    func centeredLibraryMovesAsideToFitSettingsWithoutMovingPrompter() throws {
        let prompter = CGRect(x: 430, y: 810, width: 650, height: 130)
        let arrangement = try #require(AppWindowFrameCalculator.makingRoom(
            for: CGRect(x: 526, y: 300, width: 460, height: 380),
            moving: CGRect(x: 306, y: 160, width: 900, height: 600),
            in: screen,
            avoiding: [prompter]
        ))
        #expect(!arrangement.existing.intersects(arrangement.opening))
        #expect(!arrangement.existing.intersects(prompter))
        #expect(!arrangement.opening.intersects(prompter))
        #expect(screen.contains(arrangement.existing))
        #expect(screen.contains(arrangement.opening))
    }
}
