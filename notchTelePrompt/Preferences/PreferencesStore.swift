//
//  PreferencesStore.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// app-wide user preferences (spec §10), backed by UserDefaults. each property loads its value in init
/// and writes through on didSet so SwiftUI panes can bind directly while changes persist immediately.
/// keys are namespaced under "preferences." to keep them clear of other defaults.
@MainActor
@Observable
final class PreferencesStore {
    // MARK: - General

    var showDockIcon = false {
        didSet { defaults.set(showDockIcon, forKey: Key.showDockIcon) }
    }

    var restoreLastScript = true {
        didSet { defaults.set(restoreLastScript, forKey: Key.restoreLastScript) }
    }

    var openEditorOnLaunch = false {
        didSet { defaults.set(openEditorOnLaunch, forKey: Key.openEditorOnLaunch) }
    }

    /// id of the script last shown in the prompter, restored on launch when restoreLastScript is on.
    /// stored as its uuid string; nil clears it.
    var lastShownScriptID: UUID? {
        didSet { defaults.set(lastShownScriptID?.uuidString, forKey: Key.lastShownScriptID) }
    }

    // MARK: - Prompter

    var prompterDefaults = ScriptPrompterSettings() {
        didSet {
            persistPrompterDefaults()
            NotificationCenter.default.post(name: .preferencesPrompterDefaultsDidChange, object: nil)
        }
    }

    var countdown: CountdownOption = .three {
        didSet { defaults.set(countdown.persistedValue, forKey: Key.countdown) }
    }

    // MARK: - Voice

    var voiceSensitivity = 0.5 {
        didSet {
            defaults.set(voiceSensitivity, forKey: Key.voiceSensitivity)
            NotificationCenter.default.post(name: .preferencesVoiceConfigDidChange, object: nil)
        }
    }

    var silenceDelay = 1.0 {
        didSet {
            defaults.set(silenceDelay, forKey: Key.silenceDelay)
            NotificationCenter.default.post(name: .preferencesVoiceConfigDidChange, object: nil)
        }
    }

    var pauseOnSilence = true {
        didSet {
            defaults.set(pauseOnSilence, forKey: Key.pauseOnSilence)
            // re-settle live playback: toggling this while already silent must pause/resume immediately.
            NotificationCenter.default.post(name: .preferencesVoiceConfigDidChange, object: nil)
        }
    }

    /// the detector configuration derived from the current voice preferences.
    var voiceConfiguration: VoiceActivityConfiguration {
        .make(sensitivity: voiceSensitivity, silenceDelay: silenceDelay)
    }

    @ObservationIgnored private let defaults: UserDefaults

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.showDockIcon) != nil {
            showDockIcon = defaults.bool(forKey: Key.showDockIcon)
        }
        if defaults.object(forKey: Key.restoreLastScript) != nil {
            restoreLastScript = defaults.bool(forKey: Key.restoreLastScript)
        }
        if defaults.object(forKey: Key.openEditorOnLaunch) != nil {
            openEditorOnLaunch = defaults.bool(forKey: Key.openEditorOnLaunch)
        }
        if let stored = defaults.string(forKey: Key.lastShownScriptID) {
            lastShownScriptID = UUID(uuidString: stored)
        }
        if
            let data = defaults.data(forKey: Key.prompterDefaults),
            let decoded = try? JSONDecoder().decode(ScriptPrompterSettings.self, from: data)
        {
            prompterDefaults = decoded
        }
        if defaults.object(forKey: Key.countdown) != nil {
            countdown = CountdownOption(persistedValue: defaults.integer(forKey: Key.countdown))
        }
        if defaults.object(forKey: Key.voiceSensitivity) != nil {
            voiceSensitivity = defaults.double(forKey: Key.voiceSensitivity)
        }
        if defaults.object(forKey: Key.silenceDelay) != nil {
            silenceDelay = defaults.double(forKey: Key.silenceDelay)
        }
        if defaults.object(forKey: Key.pauseOnSilence) != nil {
            pauseOnSilence = defaults.bool(forKey: Key.pauseOnSilence)
        }
    }

    // MARK: - Persistence

    private func persistPrompterDefaults() {
        guard let data = try? JSONEncoder().encode(prompterDefaults) else {
            return
        }
        defaults.set(data, forKey: Key.prompterDefaults)
    }

    // MARK: - Keys

    private enum Key {
        static let showDockIcon = "preferences.showDockIcon"
        static let restoreLastScript = "preferences.restoreLastScript"
        static let openEditorOnLaunch = "preferences.openEditorOnLaunch"
        static let lastShownScriptID = "preferences.lastShownScriptID"
        static let prompterDefaults = "preferences.prompterDefaults"
        static let countdown = "preferences.countdown"
        static let voiceSensitivity = "preferences.voiceSensitivity"
        static let silenceDelay = "preferences.silenceDelay"
        static let pauseOnSilence = "preferences.pauseOnSilence"
    }
}
