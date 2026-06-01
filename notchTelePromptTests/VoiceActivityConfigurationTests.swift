//
//  VoiceActivityConfigurationTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct VoiceActivityConfigurationTests {
    // MARK: - Defaults mapping

    @Test
    func midSensitivityMatchesDetectorDefaults() {
        let config = VoiceActivityConfiguration.make(sensitivity: 0.5, silenceDelay: 1.0)
        let tolerance: Float = 0.0001
        #expect(abs(config.speechThreshold - 0.05) < tolerance)
        #expect(abs(config.silenceThreshold - 0.02) < tolerance)
        #expect(config.silenceDelay == 1.0)
    }

    // MARK: - Hysteresis

    @Test
    func hysteresisHoldsAcrossSensitivityRange() {
        for sensitivity in [0.0, 0.5, 1.0] {
            let config = VoiceActivityConfiguration.make(sensitivity: sensitivity, silenceDelay: 1.0)
            #expect(config.speechThreshold > config.silenceThreshold)
        }
    }

    // MARK: - Monotonicity

    @Test
    func higherSensitivityLowersSpeechThreshold() {
        let low = VoiceActivityConfiguration.make(sensitivity: 0.2, silenceDelay: 1.0)
        let high = VoiceActivityConfiguration.make(sensitivity: 0.8, silenceDelay: 1.0)
        #expect(low.speechThreshold > high.speechThreshold)
    }

    // MARK: - Silence delay clamping

    @Test
    func silenceDelayClampsBelowMinimum() {
        let config = VoiceActivityConfiguration.make(sensitivity: 0.5, silenceDelay: 0.0)
        #expect(config.silenceDelay == 0.2)
    }

    @Test
    func silenceDelayClampsAboveMaximum() {
        let config = VoiceActivityConfiguration.make(sensitivity: 0.5, silenceDelay: 5.0)
        #expect(config.silenceDelay == 3.0)
    }
}
