//
//  PrompterViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// holds the state the prompter overlay renders. owns the scroll engine that drives playback;
/// the current reading line is derived from the engine's scroll offset (phase 7).
@MainActor
@Observable
final class PrompterViewModel {
    /// the scroll engine driving auto-scroll, offset and the playback state machine.
    let scrollEngine = ScrollEngine()

    /// the chosen pre-start countdown (spec §17); applied on start / restart.
    var countdown: CountdownOption = .three

    /// the script being shown. setting it resets the engine to the top and refreshes the font size
    /// mirror from the script's stored settings.
    var currentScript: Script? {
        didSet {
            scrollEngine.stop()
            reloadFontSize()
            syncEngineGeometry()
            reconcileVoicePlayback()
        }
    }

    /// the per-script prompter font size in points, mirrored from the current script's settings
    /// (falling back to the default). the view layer binds to this instead of reading the @Model.
    private(set) var fontSize = PrompterFontSize.default

    /// the current reading line, derived from the engine's scroll offset and the line geometry.
    var currentLineIndex: Int {
        PrompterLayoutMetrics.lineIndex(
            forOffset: scrollEngine.offset,
            lineCount: lines.count,
            fontSize: fontSize,
            lineSpacing: lineSpacing
        )
    }

    /// reading progress in [0, 1], taken from the engine's scroll position.
    var progress: Double {
        scrollEngine.progress
    }

    /// vertical spacing between rendered lines (fixed default for v1.0).
    var lineSpacing: Double {
        Double(PrompterStyle.lineSpacing)
    }

    /// the script text split into renderable lines. memoized so it resplits only when the text
    /// actually changes (not every render or scroll tick), while still reflecting live edits.
    var lines: [String] {
        let text = currentScript?.text ?? ""
        if cachedText != text {
            cachedText = text
            cachedLines = PrompterTextSplitter.lines(from: text)
        }
        return cachedLines
    }

    @ObservationIgnored private var cachedText: String?
    @ObservationIgnored private var cachedLines: [String] = []

    /// whether voice-follow is currently engaged (the user's intent); the indicator shows while true.
    private(set) var isVoiceModeEnabled = false

    /// mirrors the voice engine's speaking state for the overlay indicator (observed for SwiftUI).
    private(set) var isSpeaking = false

    /// fired when enabling voice fails because microphone permission is denied or restricted, so the
    /// host can guide the user to System Settings (spec §9.1).
    @ObservationIgnored var onVoicePermissionDenied: (() -> Void)?

    /// fired when capture can't start despite permission (no input device, mic busy, engine failure),
    /// so the host can let the user know voice-follow didn't actually begin.
    @ObservationIgnored var onVoiceUnavailable: (() -> Void)?

    @ObservationIgnored private let voiceEngine = VoiceEngine()

    /// persists font-size changes; injected so the overlay writes through the same store as the editor.
    @ObservationIgnored private let store: ScriptStore?

    /// app preferences; read for the voice-follow tuning (sensitivity, silence delay, pause-on-silence).
    @ObservationIgnored private let preferences: PreferencesStore
    @ObservationIgnored private var fontSizeObserver: NotificationObserverToken?
    @ObservationIgnored private var voiceConfigObserver: NotificationObserverToken?

    init(store: ScriptStore? = nil, preferences: PreferencesStore = PreferencesStore()) {
        self.store = store
        self.preferences = preferences
        observeFontSizeChanges()
        observeVoiceConfigChanges()
        syncEngineGeometry()
        scrollEngine.setSpeed(.default(fontSize: fontSize, lineSpacing: lineSpacing))

        voiceEngine.onSpeakingChanged = { [weak self] speaking in
            guard let self else {
                return
            }
            isSpeaking = speaking
            reconcileVoicePlayback()
        }
        voiceEngine.onPermissionDenied = { [weak self] in
            guard let self else {
                return
            }
            isVoiceModeEnabled = false
            isSpeaking = false
            scrollEngine.isVoiceDriven = false
            onVoicePermissionDenied?()
        }
        voiceEngine.onUnavailable = { [weak self] in
            guard let self else {
                return
            }
            isVoiceModeEnabled = false
            isSpeaking = false
            scrollEngine.isVoiceDriven = false
            onVoiceUnavailable?()
        }
    }

    // MARK: - Playback

    /// starts (honoring the configured countdown), pauses or resumes depending on the current state.
    /// used by the overlay controls, the menu bar, global hotkeys and the mini control panel so play/
    /// pause behaves the same everywhere — unlike the engine's countdown-less toggle.
    func playPause() {
        switch scrollEngine.state {
        case .playing:
            scrollEngine.pause()
        case .paused:
            scrollEngine.resume()
        case .idle, .finished:
            scrollEngine.start(countdown: countdown)
        case .countdown:
            break
        }
    }

    /// stops playback and returns to the top.
    func stop() {
        scrollEngine.stop()
    }

    func restart() {
        scrollEngine.restart(countdown: countdown)
    }

    func setHovering(_ hovering: Bool) {
        scrollEngine.setHovering(hovering)
        reconcileVoicePlayback()
    }

    /// the viewport height measured by the view; feeds the engine so max offset / progress are right.
    func setViewportHeight(_ height: Double) {
        scrollEngine.viewportHeight = height
    }

    // MARK: - Voice

    /// toggles voice-follow on/off. enabling requests microphone permission on first use.
    func toggleVoiceMode() {
        if isVoiceModeEnabled {
            disableVoiceMode()
        } else {
            // voice-follow needs a script to follow; without one, don't arm the microphone.
            guard currentScript != nil else {
                return
            }
            isVoiceModeEnabled = true
            scrollEngine.isVoiceDriven = true
            voiceEngine.updateConfiguration(preferences.voiceConfiguration)
            voiceEngine.enable()
            // settle playback immediately: silence on enable should hold the scroll until speech.
            reconcileVoicePlayback()
        }
    }

    /// turns voice-follow fully off and releases the microphone; called both by the toggle and whenever
    /// the overlay is dismissed, so the mic never keeps capturing once the prompter is hidden.
    func disableVoiceMode() {
        guard isVoiceModeEnabled else {
            return
        }
        isVoiceModeEnabled = false
        isSpeaking = false
        scrollEngine.isVoiceDriven = false
        voiceEngine.disable()
    }

    /// reconciles scroll playback with the live voice inputs: scroll only while speaking and not hovering
    /// (explicit hover-to-pause wins), pause otherwise. level-driven rather than edge-driven, so enabling
    /// voice, switching scripts and hover changes all settle correctly. a no-op when voice mode is off.
    /// when the pause-on-silence preference is off, a silence no longer pauses (only hover does), so the
    /// scroll keeps running once speech has started it.
    private func reconcileVoicePlayback() {
        guard isVoiceModeEnabled, currentScript != nil else {
            return
        }
        let shouldScroll = isSpeaking && !scrollEngine.isHovering
        if shouldScroll {
            switch scrollEngine.state {
            case .idle:
                scrollEngine.start(countdown: .off)
            case .paused:
                scrollEngine.resume()
            case .playing, .countdown, .finished:
                break
            }
        } else {
            let shouldPause = scrollEngine.isHovering || preferences.pauseOnSilence
            if shouldPause, scrollEngine.state == .playing {
                scrollEngine.pause()
            }
        }
    }

    // MARK: - Speed

    /// current speed expressed in words-per-minute for the active geometry.
    var wordsPerMinute: Double {
        ScrollSpeed(pointsPerSecond: scrollEngine.pointsPerSecond)
            .wordsPerMinute(fontSize: fontSize, lineSpacing: lineSpacing)
    }

    func increaseSpeed() {
        applyWordsPerMinute(wordsPerMinute + Self.wpmStep)
    }

    func decreaseSpeed() {
        applyWordsPerMinute(wordsPerMinute - Self.wpmStep)
    }

    private static let wpmStep = 10.0

    private func applyWordsPerMinute(_ wpm: Double) {
        let speed = ScrollSpeed(wordsPerMinute: wpm, fontSize: fontSize, lineSpacing: lineSpacing)
            .clamped(fontSize: fontSize, lineSpacing: lineSpacing)
        scrollEngine.setSpeed(speed)
    }

    // MARK: - Font size

    func increaseFontSize() {
        applyFontSize(PrompterFontSize.incremented(fontSize))
    }

    func decreaseFontSize() {
        applyFontSize(PrompterFontSize.decremented(fontSize))
    }

    /// clamps, mirrors, persists through the store and broadcasts so the editor stays in sync.
    private func applyFontSize(_ newValue: Double) {
        guard let script = currentScript else {
            return
        }
        let clamped = PrompterFontSize.clamp(newValue)
        guard clamped != fontSize else {
            return
        }
        fontSize = clamped
        syncEngineGeometry()
        try? store?.setFontSize(clamped, on: script)
        NotificationCenter.default.post(
            name: .scriptFontSizeDidChange,
            object: nil,
            userInfo: [ScriptFontSizeChange.scriptIDKey: script.id]
        )
    }

    /// refreshes the mirror from the current script's stored settings, defaulting when none exist.
    private func reloadFontSize() {
        fontSize = PrompterFontSize.clamp(currentScript?.settingsBlob?.fontSize ?? PrompterFontSize.default)
        syncEngineGeometry()
    }

    /// keeps the engine's geometry inputs (font size, line spacing, content height) in step so its
    /// offset math, max offset and progress stay correct. content height is computed, not measured.
    /// called from explicit mutation points (script / font changes) and from the view when the line
    /// count changes, never from inside a view body, so it can safely mutate the observable engine.
    func syncEngineGeometry() {
        scrollEngine.fontSize = fontSize
        scrollEngine.lineSpacing = lineSpacing
        scrollEngine.contentHeight = PrompterLayoutMetrics.contentHeight(
            lineCount: lines.count,
            fontSize: fontSize,
            lineSpacing: lineSpacing
        )
    }

    /// re-reads the size when another surface (the editor) changes it for the script we are showing.
    private func observeFontSizeChanges() {
        fontSizeObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .scriptFontSizeDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let changedID = notification.userInfo?[ScriptFontSizeChange.scriptIDKey] as? UUID
            Task { @MainActor in
                guard let self, let changedID, self.currentScript?.id == changedID else {
                    return
                }
                self.reloadFontSize()
            }
        })
    }

    /// retunes the running voice engine when the sensitivity / silence-delay preferences change. the
    /// engine ignores the update harmlessly when capture isn't running, so no running-state check is needed.
    private func observeVoiceConfigChanges() {
        voiceConfigObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .preferencesVoiceConfigDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.voiceEngine.updateConfiguration(self.preferences.voiceConfiguration)
            }
        })
    }
}
