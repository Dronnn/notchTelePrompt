//
//  ScrollEngineTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

@MainActor
struct ScrollEngineTests {
    /// a deterministic engine: no driver task, so synthetic `advance(to:)` calls fully control timing.
    private func makeEngine(
        speed: Double = 100,
        contentHeight: Double = 1_000,
        viewportHeight: Double = 100
    ) -> ScrollEngine {
        let engine = ScrollEngine(autoTick: false)
        engine.contentHeight = contentHeight
        engine.viewportHeight = viewportHeight
        engine.fontSize = 20
        engine.lineSpacing = 10
        engine.pointsPerSecond = speed
        return engine
    }

    // MARK: - Drift-free advance

    @Test
    func offsetMatchesSpeedTimesElapsed() {
        let engine = makeEngine(speed: 100)
        engine.start(countdown: .off)
        engine.advance(to: 0) // seed clock
        engine.advance(to: 2) // 2 seconds at 100 pt/s -> 200
        #expect(abs(engine.offset - 200) < 0.0001)
    }

    @Test
    func manySmallStepsDoNotDrift() {
        let engine = makeEngine(speed: 60)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        // 600 steps of ~16.6ms = 10 seconds; offset should be 600 pt within a tiny tolerance.
        var time = 0.0
        let step = 1.0 / 60.0
        for _ in 0 ..< 600 {
            time += step
            engine.advance(to: time)
        }
        #expect(abs(engine.offset - 600) < 0.5)
    }

    @Test
    func irregularDeltasStillTrackTotalElapsed() {
        let engine = makeEngine(speed: 50)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        for time in [0.3, 0.31, 1.0, 3.7, 4.0] {
            engine.advance(to: time)
        }
        // total elapsed 4s at 50 pt/s = 200.
        #expect(abs(engine.offset - 200) < 0.0001)
    }

    // MARK: - Clamp at end -> finished

    @Test
    func reachingMaxOffsetFinishes() {
        let engine = makeEngine(speed: 1_000, contentHeight: 1_000, viewportHeight: 100)
        // maxOffset = contentHeight - fontSize = 980.
        engine.start(countdown: .off)
        engine.advance(to: 0)
        engine.advance(to: 5) // 5000 pt requested, clamps to 980.
        #expect(abs(engine.offset - engine.maxOffset) < 0.0001)
        #expect(engine.state == .finished)
    }

    @Test
    func finishedStaysAtEndOnFurtherAdvance() {
        let engine = makeEngine(speed: 1_000)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        engine.advance(to: 5)
        let end = engine.offset
        engine.advance(to: 6)
        #expect(engine.offset == end)
        #expect(engine.state == .finished)
    }

    // MARK: - Pause / resume

    @Test
    func pausedDoesNotAdvance() {
        let engine = makeEngine(speed: 100)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        engine.advance(to: 1) // 100
        engine.pause()
        engine.advance(to: 5) // should not move
        #expect(abs(engine.offset - 100) < 0.0001)
        #expect(engine.state == .paused)
    }

    @Test
    func resumeContinuesFromWhereItPaused() {
        let engine = makeEngine(speed: 100)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        engine.advance(to: 1) // 100
        engine.pause()
        engine.resume()
        engine.advance(to: 10) // seed after resume (clock was reset on resume)
        engine.advance(to: 11) // +1s -> +100
        #expect(abs(engine.offset - 200) < 0.0001)
        #expect(engine.state == .playing)
    }

    // MARK: - Stop resets

    @Test
    func stopReturnsToIdleAtTop() {
        let engine = makeEngine(speed: 100)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        engine.advance(to: 2)
        engine.stop()
        #expect(engine.offset == 0)
        #expect(engine.state == .idle)
    }

    // MARK: - Nudge

    @Test
    func nudgeShiftsOffsetClamped() {
        let engine = makeEngine(speed: 0)
        engine.nudge(by: 50)
        #expect(abs(engine.offset - 50) < 0.0001)
        engine.nudge(by: -999)
        #expect(engine.offset == 0)
        engine.nudge(by: 99_999)
        #expect(abs(engine.offset - engine.maxOffset) < 0.0001)
    }

    @Test
    func nudgeDuringPlaybackRebasesSmoothly() {
        let engine = makeEngine(speed: 100)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        engine.advance(to: 1) // 100
        engine.nudge(by: 50) // jump to 150
        engine.advance(to: 2) // +1s at 100 from 150 -> 250
        #expect(abs(engine.offset - 250) < 0.0001)
    }

    // MARK: - Countdown

    @Test
    func countdownDelaysPlayingThenScrolls() {
        let engine = makeEngine(speed: 100)
        engine.start(countdown: .three)
        #expect(engine.state == .countdown)
        engine.advance(to: 0) // seed + fix end at 3
        #expect(engine.state == .countdown)
        #expect(engine.offset == 0)
        engine.advance(to: 2) // still counting
        #expect(engine.state == .countdown)
        engine.advance(to: 3) // countdown done -> playing
        #expect(engine.state == .playing)
        engine.advance(to: 4) // 1s of scrolling
        #expect(abs(engine.offset - 100) < 0.0001)
    }

    // MARK: - Hover

    @Test
    func hoverPausesWhilePlaying() {
        let engine = makeEngine(speed: 100)
        engine.start(countdown: .off)
        engine.advance(to: 0)
        engine.advance(to: 1)
        engine.setHovering(true)
        #expect(engine.state == .paused)
        engine.advance(to: 5)
        #expect(abs(engine.offset - 100) < 0.0001)
    }

    @Test
    func hoverDoesNotPauseWhenIdle() {
        let engine = makeEngine(speed: 100)
        engine.setHovering(true)
        #expect(engine.state == .idle)
    }

    // MARK: - Progress

    @Test
    func progressTracksOffsetOverMaxOffset() {
        let engine = makeEngine(speed: 100, contentHeight: 1_000, viewportHeight: 100)
        #expect(engine.progress == 0)
        engine.nudge(by: engine.maxOffset / 2)
        #expect(abs(engine.progress - 0.5) < 0.0001)
        engine.jumpToEnd()
        #expect(abs(engine.progress - 1) < 0.0001)
    }
}
