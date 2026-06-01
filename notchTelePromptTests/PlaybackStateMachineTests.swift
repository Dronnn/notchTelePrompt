//
//  PlaybackStateMachineTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

struct PlaybackStateMachineTests {
    // MARK: - Start / countdown path

    @Test
    func startFromIdleEntersCountdown() {
        #expect(PlaybackStateMachine.next(from: .idle, on: .start) == .countdown)
    }

    @Test
    func startFromFinishedEntersCountdown() {
        #expect(PlaybackStateMachine.next(from: .finished, on: .start) == .countdown)
    }

    @Test
    func countdownFinishedEntersPlaying() {
        #expect(PlaybackStateMachine.next(from: .countdown, on: .countdownFinished) == .playing)
    }

    // MARK: - Pause / resume

    @Test
    func pauseFromPlaying() {
        #expect(PlaybackStateMachine.next(from: .playing, on: .pause) == .paused)
    }

    @Test
    func resumeFromPaused() {
        #expect(PlaybackStateMachine.next(from: .paused, on: .resume) == .playing)
    }

    // MARK: - Reached end

    @Test
    func reachedEndFromPlayingFinishes() {
        #expect(PlaybackStateMachine.next(from: .playing, on: .reachedEnd) == .finished)
    }

    // MARK: - Stop

    @Test
    func stopFromAnyActiveStateReturnsToIdle() {
        #expect(PlaybackStateMachine.next(from: .countdown, on: .stop) == .idle)
        #expect(PlaybackStateMachine.next(from: .playing, on: .stop) == .idle)
        #expect(PlaybackStateMachine.next(from: .paused, on: .stop) == .idle)
        #expect(PlaybackStateMachine.next(from: .finished, on: .stop) == .idle)
    }

    // MARK: - Restart

    @Test
    func restartFromAnyStateEntersCountdown() {
        #expect(PlaybackStateMachine.next(from: .idle, on: .restart) == .countdown)
        #expect(PlaybackStateMachine.next(from: .playing, on: .restart) == .countdown)
        #expect(PlaybackStateMachine.next(from: .paused, on: .restart) == .countdown)
        #expect(PlaybackStateMachine.next(from: .finished, on: .restart) == .countdown)
    }

    // MARK: - Invalid transitions are no-ops

    @Test
    func pauseIsIgnoredWhenNotPlaying() {
        #expect(PlaybackStateMachine.next(from: .idle, on: .pause) == .idle)
        #expect(PlaybackStateMachine.next(from: .paused, on: .pause) == .paused)
        #expect(PlaybackStateMachine.next(from: .countdown, on: .pause) == .countdown)
        #expect(PlaybackStateMachine.next(from: .finished, on: .pause) == .finished)
    }

    @Test
    func resumeIsIgnoredWhenNotPaused() {
        #expect(PlaybackStateMachine.next(from: .idle, on: .resume) == .idle)
        #expect(PlaybackStateMachine.next(from: .playing, on: .resume) == .playing)
        #expect(PlaybackStateMachine.next(from: .countdown, on: .resume) == .countdown)
        #expect(PlaybackStateMachine.next(from: .finished, on: .resume) == .finished)
    }

    @Test
    func countdownFinishedIsIgnoredOutsideCountdown() {
        #expect(PlaybackStateMachine.next(from: .idle, on: .countdownFinished) == .idle)
        #expect(PlaybackStateMachine.next(from: .playing, on: .countdownFinished) == .playing)
        #expect(PlaybackStateMachine.next(from: .paused, on: .countdownFinished) == .paused)
        #expect(PlaybackStateMachine.next(from: .finished, on: .countdownFinished) == .finished)
    }

    @Test
    func reachedEndIsIgnoredOutsidePlaying() {
        #expect(PlaybackStateMachine.next(from: .idle, on: .reachedEnd) == .idle)
        #expect(PlaybackStateMachine.next(from: .countdown, on: .reachedEnd) == .countdown)
        #expect(PlaybackStateMachine.next(from: .paused, on: .reachedEnd) == .paused)
        #expect(PlaybackStateMachine.next(from: .finished, on: .reachedEnd) == .finished)
    }

    @Test
    func startIsIgnoredWhileActive() {
        #expect(PlaybackStateMachine.next(from: .countdown, on: .start) == .countdown)
        #expect(PlaybackStateMachine.next(from: .playing, on: .start) == .playing)
        #expect(PlaybackStateMachine.next(from: .paused, on: .start) == .paused)
    }
}
