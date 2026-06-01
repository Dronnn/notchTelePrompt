//
//  PlaybackEvent.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

/// inputs that drive the playback state machine. the engine decides which event to send
/// (e.g. `start` lands in countdown vs playing depending on the chosen CountdownOption).
nonisolated enum PlaybackEvent {
    /// user pressed start; engine sends this with the countdown already resolved.
    case start
    /// the countdown reached zero.
    case countdownFinished
    /// pause auto-scroll.
    case pause
    /// resume auto-scroll after a pause.
    case resume
    /// stop and return to idle.
    case stop
    /// the offset hit the end of the script.
    case reachedEnd
    /// restart from the beginning.
    case restart
}
