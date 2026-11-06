//
//  VoiceActivityDetectorTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

struct VoiceActivityDetectorTests {
    // MARK: - Starting speech

    @Test
    func levelAboveSpeechThresholdStartsSpeaking() {
        var detector = VoiceActivityDetector()
        let speaking = detector.update(level: 0.1, at: 0)
        #expect(speaking)
    }

    @Test
    func sustainZoneDoesNotStartSpeaking() {
        var detector = VoiceActivityDetector(speechThreshold: 0.05, silenceThreshold: 0.02)
        // a level between the thresholds must not start speaking on its own.
        let speaking = detector.update(level: 0.03, at: 0)
        #expect(!speaking)
    }

    @Test
    func defaultConfigurationDetectsQuietSpeechAndIgnoresBackgroundNoise() {
        var detector = VoiceActivityDetector()
        detector.apply(.default)

        let background = detector.update(level: 0.0004, at: 0)
        let speech = detector.update(level: 0.01, at: 0.1)
        #expect(!background)
        #expect(speech)
        // background levels after speech keep the short pause debounce, then return to silence.
        let shortPause = detector.update(level: 0.0004, at: 0.5)
        let silence = detector.update(level: 0.0004, at: 1.2)
        let continuedBackground = detector.update(level: 0.0004, at: 1.3)
        #expect(shortPause)
        #expect(!silence)
        #expect(!continuedBackground)
    }

    // MARK: - Silence delay debounce

    @Test
    func silenceLongerThanDelayStopsSpeaking() {
        var detector = VoiceActivityDetector()
        let started = detector.update(level: 0.1, at: 0)
        #expect(started)
        // still within the silence delay window.
        let stillSpeaking = detector.update(level: 0.0, at: 0.5)
        #expect(stillSpeaking)
        // delay has now elapsed since the last loud sample.
        let stopped = detector.update(level: 0.0, at: 1.0)
        #expect(!stopped)
    }

    @Test
    func silenceShorterThanDelayKeepsSpeaking() {
        var detector = VoiceActivityDetector()
        let started = detector.update(level: 0.1, at: 0)
        #expect(started)
        let stillSpeaking = detector.update(level: 0.0, at: 0.3)
        #expect(stillSpeaking)
    }

    // MARK: - Sustain zone

    @Test
    func sustainZoneKeepsSpeakingAndResetsTimer() {
        var detector = VoiceActivityDetector(speechThreshold: 0.05, silenceThreshold: 0.02)
        let started = detector.update(level: 0.1, at: 0)
        #expect(started)
        // levels between the thresholds keep speaking alive and reset the silence timer each time.
        let sustain1 = detector.update(level: 0.03, at: 0.6)
        let sustain2 = detector.update(level: 0.03, at: 1.2)
        let sustain3 = detector.update(level: 0.03, at: 1.8)
        #expect(sustain1)
        #expect(sustain2)
        #expect(sustain3)
        // dropping into silence: still speaking until the delay elapses from the last sustain sample.
        let stillSpeaking = detector.update(level: 0.0, at: 2.0)
        #expect(stillSpeaking)
        // 3.0 - 1.8 is comfortably past the 1.0s delay (avoids the exact floating-point boundary).
        let stopped = detector.update(level: 0.0, at: 3.0)
        #expect(!stopped)
    }

    // MARK: - Reset

    @Test
    func resetClearsSpeakingState() {
        var detector = VoiceActivityDetector()
        let started = detector.update(level: 0.1, at: 0)
        #expect(started)
        detector.reset()
        #expect(!detector.isSpeaking)
    }
}
