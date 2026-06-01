//
//  PlaybackStateMachine.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

/// pure transition table for the prompter playback lifecycle (spec §45).
/// invalid (state, event) pairs leave the state unchanged so callers can fire events freely.
///
/// the spec models the start path as `idle -> countdown -> playing`. when no countdown is
/// configured the engine fires `start` then immediately `countdownFinished`, so a countdown-off
/// start still resolves to `.playing` without a separate event. likewise `restart` first resets
/// the offset, then re-runs the same start path. the spec's `stopped` state is collapsed into
/// `idle` here, since both mean "not playing, pinned to the top".
nonisolated enum PlaybackStateMachine {
    /// the state reached from `state` on `event`; unchanged for transitions the spec does not allow.
    static func next(from state: PlaybackState, on event: PlaybackEvent) -> PlaybackState {
        switch (state, event) {
        // start / restart resolve through countdown.
        case (.idle, .start),
             (.finished, .start),
             (.idle, .restart),
             (.playing, .restart),
             (.paused, .restart),
             (.finished, .restart):
            .countdown

        // countdown completes into playing.
        case (.countdown, .countdownFinished):
            .playing

        // pause / resume.
        case (.playing, .pause):
            .paused

        case (.paused, .resume):
            .playing

        // reaching the end finishes playback.
        case (.playing, .reachedEnd):
            .finished

        // stop from any active state returns to idle.
        case (.countdown, .stop),
             (.playing, .stop),
             (.paused, .stop),
             (.finished, .stop):
            .idle

        // everything else is a no-op.
        default:
            state
        }
    }
}
