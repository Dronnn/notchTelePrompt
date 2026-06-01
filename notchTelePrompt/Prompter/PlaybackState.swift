//
//  PlaybackState.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

/// the prompter playback lifecycle (spec §45). pure value type, nonisolated so the engine and
/// nonisolated tests can both reason about it.
nonisolated enum PlaybackState: Equatable {
    /// not started; offset pinned to the top.
    case idle
    /// counting down before scrolling begins.
    case countdown
    /// auto-scrolling.
    case playing
    /// scrolling temporarily halted; resumable.
    case paused
    /// reached the end of the script.
    case finished
}
