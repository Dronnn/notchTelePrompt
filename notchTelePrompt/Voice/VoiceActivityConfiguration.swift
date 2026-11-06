//
//  VoiceActivityConfiguration.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// the tunable inputs of VoiceActivityDetector, derived from a single user-facing sensitivity plus a
/// silence delay. keeping the mapping here (instead of exposing three raw thresholds in preferences)
/// preserves the detector's hysteresis invariant (speechThreshold > silenceThreshold) by construction.
/// pure value type, nonisolated and testable.
nonisolated struct VoiceActivityConfiguration: Equatable {
    let speechThreshold: Float
    let silenceThreshold: Float
    let silenceDelay: TimeInterval

    // MARK: - Factory

    /// maps a 0...1 sensitivity (higher = more sensitive = lower thresholds) and a silence delay to a
    /// configuration. silenceThreshold trails speechThreshold so the sustain zone (hysteresis) always
    /// holds; both inputs are clamped so out-of-range preferences can't break the detector. the RMS
    /// speech threshold ranges from 0.009 at low sensitivity to 0.001 at high sensitivity, allowing
    /// quieter microphone speech to trigger voice-follow.
    static func make(sensitivity: Double, silenceDelay: TimeInterval) -> VoiceActivityConfiguration {
        let s = min(max(sensitivity, 0), 1)
        let speech = Float(0.009 - 0.008 * s)
        return VoiceActivityConfiguration(
            speechThreshold: speech,
            silenceThreshold: speech * 0.4,
            silenceDelay: min(max(silenceDelay, 0.2), 3.0)
        )
    }

    /// matches the detector's defaults: speech 0.005, silence 0.002, delay 1.0.
    static let `default` = make(sensitivity: 0.5, silenceDelay: 1.0)
}
