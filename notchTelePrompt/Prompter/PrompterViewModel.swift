//
//  PrompterViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// holds the state the prompter overlay renders. owns the scroll engine that drives playback;
/// the current reading line is derived from the engine's scroll offset (phase 7).
@MainActor
@Observable
final class PrompterViewModel {
    /// the scroll engine driving auto-scroll, offset and the playback state machine.
    let scrollEngine = ScrollEngine()

    /// the chosen pre-start countdown (spec §17); applied on start / restart. driven by the preferences
    /// pane, so reading it during a view body also observes the shared store.
    var countdown: CountdownOption {
        preferences.countdown
    }

    /// the script being shown. setting it resets the engine to the top, refreshes the font size mirror
    /// from the global default and re-seeds the scroll speed from the current global default.
    var currentScript: Script? {
        didSet {
            scrollEngine.stop()
            reloadFontSize()
            syncEngineGeometry()
            seedScrollSpeed()
            reconcileVoicePlayback()
        }
    }

    /// the prompter font size in points, mirrored from the global prompter defaults. the view layer
    /// binds to this instead of reading the store directly.
    private(set) var fontSize = PrompterFontSize.default

    /// whether the overlay panel is currently on screen. the mini control panel observes this to flip
    /// its show/hide toggle, since it stays open while the overlay is hidden.
    private(set) var isOverlayVisible = false

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

    // MARK: - Resolved appearance

    /// the text colour resolved from the global prompter defaults (falling back to white). reading this
    /// in a view body observes the shared store, so a colour change in the pane updates the overlay live.
    var textColor: Color {
        Color(hex: preferences.prompterDefaults.textColorHex) ?? .white
    }

    /// the overlay background opacity from the global prompter defaults; live for the same reason.
    var backgroundOpacity: Double {
        preferences.prompterDefaults.backgroundOpacity
    }

    /// the text's multiline alignment derived from the global alignment default.
    var textAlignment: TextAlignment {
        switch preferences.prompterDefaults.alignment {
        case .left: .leading
        case .center: .center
        case .right: .trailing
        }
    }

    /// the line stack's horizontal alignment derived from the global alignment default.
    var stackAlignment: HorizontalAlignment {
        switch preferences.prompterDefaults.alignment {
        case .left: .leading
        case .center: .center
        case .right: .trailing
        }
    }

    /// vertical spacing between rendered lines, resolved from the global prompter defaults.
    var lineSpacing: Double {
        preferences.prompterDefaults.lineSpacing
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

    /// app preferences; read for the voice-follow tuning (sensitivity, silence delay, pause-on-silence).
    @ObservationIgnored private let preferences: PreferencesStore
    @ObservationIgnored private var voiceConfigObserver: NotificationObserverToken?
    @ObservationIgnored private var prompterDefaultsObserver: NotificationObserverToken?

    /// the prompter defaults last applied to the engine; used to detect which field changed so a font
    /// tweak doesn't clobber a per-session speed tweak (and vice versa).
    @ObservationIgnored private var lastAppliedDefaults: ScriptPrompterSettings

    /// store is accepted for call-site compatibility; the prompter no longer persists per-script font.
    init(store _: ScriptStore? = nil, preferences: PreferencesStore = PreferencesStore()) {
        self.preferences = preferences
        lastAppliedDefaults = preferences.prompterDefaults
        observeVoiceConfigChanges()
        observePrompterDefaultsChanges()
        syncEngineGeometry()
        seedScrollSpeed()

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

    /// seeds the engine speed from the global default reading rate for the current geometry. applied on
    /// init, when the shown script changes and when the defaults change, so per-session tweaks via
    /// increaseSpeed/decreaseSpeed still take effect between re-seeds.
    private func seedScrollSpeed() {
        applyWordsPerMinute(preferences.prompterDefaults.scrollSpeed)
    }

    // MARK: - Font size

    /// whether the global font size can still grow / shrink; the controls bind to these so their enabled
    /// state is authoritative (read from the stored default) rather than the possibly-lagging mirror.
    var canIncreaseFontSize: Bool {
        preferences.prompterDefaults.fontSize < PrompterFontSize.max
    }

    var canDecreaseFontSize: Bool {
        preferences.prompterDefaults.fontSize > PrompterFontSize.min
    }

    func increaseFontSize() {
        applyFontSize(PrompterFontSize.incremented(preferences.prompterDefaults.fontSize))
    }

    func decreaseFontSize() {
        applyFontSize(PrompterFontSize.decremented(preferences.prompterDefaults.fontSize))
    }

    /// clamps and writes through the single global font default. persisting posts
    /// .preferencesPrompterDefaultsDidChange, which the observer maps back to reloadFontSize.
    private func applyFontSize(_ newValue: Double) {
        let clamped = PrompterFontSize.clamp(newValue)
        guard clamped != preferences.prompterDefaults.fontSize else {
            return
        }
        preferences.prompterDefaults.fontSize = clamped
    }

    /// refreshes the mirror from the single global font default and keeps the engine geometry in step.
    private func reloadFontSize() {
        fontSize = PrompterFontSize.clamp(preferences.prompterDefaults.fontSize)
        syncEngineGeometry()
    }

    /// keeps the engine's font size and line spacing in step (these feed the scroll-speed math). the
    /// content height is no longer computed here: the view measures the real rendered stack height (which
    /// accounts for the true font line height and any wrapping) and feeds it via setMeasuredContentHeight,
    /// so the last line lands at the center at the end. called from explicit mutation points and from the
    /// view when the line count changes, never from inside a view body, so it can mutate the engine safely.
    func syncEngineGeometry() {
        scrollEngine.fontSize = fontSize
        scrollEngine.lineSpacing = lineSpacing
    }

    /// the view's measured height of the rendered line stack; drives the scroll extent and progress so
    /// the centered reading band reaches the last line at the end and the overscroll halves are correct.
    func setMeasuredContentHeight(_ height: Double) {
        scrollEngine.contentHeight = height
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
                // settle playback so a pause-on-silence change takes effect while already silent.
                self.reconcileVoicePlayback()
            }
        })
    }

    /// reacts to a global prompter-defaults change by acting only on the field that actually changed,
    /// so a font tweak doesn't re-seed (and clobber) a per-session speed tweak and vice versa. colour,
    /// opacity and alignment need nothing here because the views read those accessors live in their body.
    private func observePrompterDefaultsChanges() {
        prompterDefaultsObserver = NotificationObserverToken(NotificationCenter.default.addObserver(
            forName: .preferencesPrompterDefaultsDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.applyDefaultsDelta()
            }
        })
    }

    /// compares the new defaults against the last-applied snapshot and updates only what changed.
    private func applyDefaultsDelta() {
        let new = preferences.prompterDefaults
        let old = lastAppliedDefaults
        lastAppliedDefaults = new

        if new.fontSize != old.fontSize {
            reloadFontSize()
        }
        if new.lineSpacing != old.lineSpacing {
            syncEngineGeometry()
        }
        if new.scrollSpeed != old.scrollSpeed {
            seedScrollSpeed()
        }
    }

    // MARK: - Overlay visibility

    /// records whether the overlay panel is on screen, so the mini panel can flip its show/hide toggle.
    func setOverlayVisible(_ visible: Bool) {
        isOverlayVisible = visible
    }
}
