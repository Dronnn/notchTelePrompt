//
//  VoiceEngine.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AVFoundation
import QuartzCore

/// captures microphone audio locally and reports whether the user is currently speaking, so the
/// prompter can scroll while they talk and pause on silence (spec §9, voice level 1). audio is
/// analysed on-device frame by frame and is never recorded, stored or sent anywhere.
@MainActor
@Observable
final class VoiceEngine {
    private(set) var authorizationStatus: VoiceAuthorizationStatus
    private(set) var isRunning = false
    private(set) var isSpeaking = false

    /// fired on the main actor whenever the speaking state flips.
    @ObservationIgnored var onSpeakingChanged: ((Bool) -> Void)?
    /// fired on the main actor when enabling fails because permission is denied or restricted.
    @ObservationIgnored var onPermissionDenied: (() -> Void)?
    /// fired on the main actor when capture can't start despite permission (no input device, mic busy,
    /// or the audio engine failing to start), so the host can reflect that voice didn't actually begin.
    @ObservationIgnored var onUnavailable: (() -> Void)?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var detector = VoiceActivityDetector()
    @ObservationIgnored private var isTapInstalled = false
    /// the user's desired run state; a toggle-off during the permission prompt cancels the pending start.
    @ObservationIgnored private var wantsRunning = false

    init() {
        authorizationStatus = Self.currentAuthorization()
    }

    // MARK: - Control

    /// enables voice follow: ensures microphone permission (requested only here, on first enable),
    /// then starts capturing.
    func enable() {
        wantsRunning = true
        switch Self.currentAuthorization() {
        case .authorized:
            authorizationStatus = .authorized
            start()
        case .notDetermined:
            requestAccessThenStart()
        case .denied, .restricted, .unavailable:
            authorizationStatus = Self.currentAuthorization()
            onPermissionDenied?()
        }
    }

    func disable() {
        wantsRunning = false
        stop()
    }

    // MARK: - Permission

    private static func currentAuthorization() -> VoiceAuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }

    private func requestAccessThenStart() {
        Task { [weak self] in
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            guard let self else {
                return
            }
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                // the user may have toggled voice back off while the prompt was up; honor that intent.
                guard wantsRunning else {
                    return
                }
                start()
            } else {
                onPermissionDenied?()
            }
        }
    }

    // MARK: - Capture

    private func start() {
        guard !isRunning else {
            return
        }
        detector.reset()
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            authorizationStatus = .unavailable
            wantsRunning = false
            onUnavailable?()
            return
        }
        input.installTap(onBus: 0, bufferSize: 4_096, format: format) { buffer, _ in
            let level = Self.rms(from: buffer)
            Task { @MainActor [weak self] in
                self?.ingest(level: level)
            }
        }
        isTapInstalled = true
        engine.prepare()
        do {
            try engine.start()
            isRunning = true
        } catch {
            removeTap()
            isRunning = false
            wantsRunning = false
            onUnavailable?()
        }
    }

    private func stop() {
        guard isRunning || isTapInstalled else {
            return
        }
        engine.stop()
        removeTap()
        isRunning = false
        detector.reset()
        if isSpeaking {
            isSpeaking = false
            onSpeakingChanged?(false)
        }
    }

    private func removeTap() {
        guard isTapInstalled else {
            return
        }
        engine.inputNode.removeTap(onBus: 0)
        isTapInstalled = false
    }

    private func ingest(level: Float) {
        let speaking = detector.update(level: level, at: CACurrentMediaTime())
        guard speaking != isSpeaking else {
            return
        }
        isSpeaking = speaking
        onSpeakingChanged?(speaking)
    }

    // MARK: - Analysis

    /// root-mean-square amplitude of the buffer's first channel in 0...1. pure; runs on the audio thread.
    nonisolated static func rms(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0] else {
            return 0
        }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else {
            return 0
        }
        var sum: Float = 0
        for index in 0 ..< frameCount {
            let sample = channel[index]
            sum += sample * sample
        }
        return (sum / Float(frameCount)).squareRoot()
    }
}
