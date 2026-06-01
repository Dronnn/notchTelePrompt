//
//  VoiceActivityDetector.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// decides whether the user is currently speaking from a stream of audio levels.
/// uses two-threshold hysteresis plus a silence-delay debounce:
///   - speechThreshold > silenceThreshold: crossing the higher level starts speaking,
///     and only dropping below the lower level counts as silence, so levels jittering
///     between the two thresholds (the sustain zone) keep speaking alive.
///   - silenceDelay debounces brief pauses between words: speaking only ends once the
///     level has stayed below silenceThreshold for at least silenceDelay seconds.
/// pure value type, nonisolated and testable.
nonisolated struct VoiceActivityDetector {
    var speechThreshold: Float = 0.05
    var silenceThreshold: Float = 0.02
    var silenceDelay: TimeInterval = 1.0

    private(set) var isSpeaking = false
    private var lastLoudTimestamp: TimeInterval?

    init(speechThreshold: Float = 0.05, silenceThreshold: Float = 0.02, silenceDelay: TimeInterval = 1.0) {
        self.speechThreshold = speechThreshold
        self.silenceThreshold = silenceThreshold
        self.silenceDelay = silenceDelay
    }

    // MARK: - Update

    /// feeds one audio level sampled at the given timestamp and returns whether the user is speaking.
    mutating func update(level: Float, at timestamp: TimeInterval) -> Bool {
        if level >= speechThreshold {
            isSpeaking = true
            lastLoudTimestamp = timestamp
        } else if isSpeaking {
            if level >= silenceThreshold {
                // sustain zone: keep alive and reset the silence timer.
                lastLoudTimestamp = timestamp
            } else if let last = lastLoudTimestamp, timestamp - last >= silenceDelay {
                isSpeaking = false
                lastLoudTimestamp = nil
            }
        }
        return isSpeaking
    }

    // MARK: - Configuration

    /// applies a configuration's thresholds and delay in one call, without touching the running state.
    mutating func apply(_ configuration: VoiceActivityConfiguration) {
        speechThreshold = configuration.speechThreshold
        silenceThreshold = configuration.silenceThreshold
        silenceDelay = configuration.silenceDelay
    }

    // MARK: - Reset

    mutating func reset() {
        isSpeaking = false
        lastLoudTimestamp = nil
    }
}
