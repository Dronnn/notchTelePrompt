//
//  VoiceEngineTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AVFoundation
@testable import notchTelePrompt
import Testing

@MainActor
struct VoiceEngineTests {
    @Test(.timeLimit(.minutes(1)))
    func audioTapRunsInDetachedTaskAndDeliversSpeakingOnMainActor() async throws {
        let voiceEngine = VoiceEngine()
        let (states, continuation) = AsyncStream<Bool>.makeStream()
        defer { continuation.finish() }
        voiceEngine.onSpeakingChanged = { speaking in
            MainActor.assertIsolated()
            continuation.yield(speaking)
        }
        let tap = voiceEngine.makeInputTap(generation: 0)

        try await Task.detached {
            let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
            let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 64))
            buffer.frameLength = 64
            let channels = try #require(buffer.floatChannelData)
            for frame in 0 ..< Int(buffer.frameLength) {
                channels[0][frame] = 0.1
            }
            tap(buffer, AVAudioTime(sampleTime: 0, atRate: format.sampleRate))
        }.value

        var iterator = states.makeAsyncIterator()
        let speaking = await iterator.next()
        #expect(speaking == true)
        #expect(voiceEngine.isSpeaking)
    }
}
