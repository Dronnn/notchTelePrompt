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
    /// bumped on every stop so speech samples queued from a previous capture session are ignored.
    @ObservationIgnored private var captureGeneration = 0
    @ObservationIgnored private var configObserver: NotificationObserverToken?

    init() {
        authorizationStatus = Self.currentAuthorization()
        observeConfigurationChanges()
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

    // MARK: - Hardware changes

    /// the audio engine stops and uninitializes when the input device or its format changes (e.g. the user
    /// plugs in headphones). rebuild the tap on the new device so voice-follow keeps working, surfacing
    /// unavailable only if the new device can't be used.
    private func observeConfigurationChanges() {
        configObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleConfigurationChange()
            }
        })
    }

    private func handleConfigurationChange() {
        guard isRunning else {
            return
        }
        stop()
        if wantsRunning {
            start()
        }
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
            // the user may have toggled voice back off while the prompt was up; honor that either way.
            guard wantsRunning else {
                return
            }
            if granted {
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
        let generation = captureGeneration
        input.installTap(onBus: 0, bufferSize: 4_096, format: format) { buffer, _ in
            let level = Self.rms(from: buffer)
            // stamp on the audio thread so the silence debounce isn't skewed by main-actor delivery lag.
            let timestamp = CACurrentMediaTime()
            Task { @MainActor [weak self] in
                self?.ingest(level: level, at: timestamp, generation: generation)
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
        // invalidate any speech samples still queued from this session before tearing down.
        captureGeneration += 1
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

    private func ingest(level: Float, at timestamp: TimeInterval, generation: Int) {
        // drop samples captured before the latest stop (a quick disable/re-enable).
        guard generation == captureGeneration else {
            return
        }
        let speaking = detector.update(level: level, at: timestamp)
        guard speaking != isSpeaking else {
            return
        }
        isSpeaking = speaking
        onSpeakingChanged?(speaking)
    }

    // MARK: - Analysis

    /// root-mean-square amplitude across the buffer's channels in 0...1. pure; runs on the audio thread.
    nonisolated static func rms(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else {
            return 0
        }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        guard channelCount > 0, frameCount > 0 else {
            return 0
        }
        var sum: Float = 0
        for channelIndex in 0 ..< channelCount {
            let samples = channels[channelIndex]
            for frameIndex in 0 ..< frameCount {
                let sample = samples[frameIndex]
                sum += sample * sample
            }
        }
        return (sum / Float(channelCount * frameCount)).squareRoot()
    }
}
