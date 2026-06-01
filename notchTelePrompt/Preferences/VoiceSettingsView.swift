//
//  VoiceSettingsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import SwiftUI

/// the voice-follow pane of preferences: detector sensitivity, silence behavior, and microphone access.
/// live tuning is handled by the store (it posts on change and the view model retunes the detector),
/// so the sliders bind straight through; this view adds no extra plumbing.
struct VoiceSettingsView: View {
    @Bindable var preferencesStore: PreferencesStore

    @State private var authorization = VoiceAuthorizationStatus.current

    var body: some View {
        Form {
            Section("Sensitivity") {
                Slider(value: $preferencesStore.voiceSensitivity, in: 0 ... 1) {
                    Text("Sensitivity")
                } minimumValueLabel: {
                    Text("Low")
                } maximumValueLabel: {
                    Text("High")
                }
                // the slider's label closure already exposes "Sensitivity"; expose the level as a percent value.
                .accessibilityValue(
                    Text(preferencesStore.voiceSensitivity, format: .percent.precision(.fractionLength(0)))
                )
                Text("Higher sensitivity picks up quieter speech, but may react to background noise.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Silence") {
                Toggle("Pause when you stop speaking", isOn: $preferencesStore.pauseOnSilence)

                LabeledContent("Silence delay") {
                    HStack {
                        Slider(value: $preferencesStore.silenceDelay, in: 0.2 ... 3.0, step: 0.1)
                            // this slider has no label closure, so name it and expose the delay in seconds.
                            .accessibilityLabel(Text("Silence delay"))
                            .accessibilityValue(
                                Text(preferencesStore.silenceDelay, format: .number.precision(.fractionLength(1)))
                                    + Text(" s")
                            )
                        Text(preferencesStore.silenceDelay, format: .number.precision(.fractionLength(1)))
                            + Text(" s")
                    }
                }
            }

            Section("Microphone") {
                MicrophoneAccessView(authorization: authorization)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            authorization = .current
        }
        // also refresh on reactivation, e.g. returning from System Settings after granting access.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            authorization = .current
        }
    }
}

// MARK: - Microphone access

/// shows the current microphone permission state and, when access is off, a way to open System Settings.
private struct MicrophoneAccessView: View {
    let authorization: VoiceAuthorizationStatus

    var body: some View {
        switch authorization {
        case .authorized:
            Label("Microphone access granted", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
        case .notDetermined:
            Text("NotchPrompter asks for microphone access the first time you turn on voice-follow.")
                .foregroundStyle(.secondary)
        case .denied, .restricted, .unavailable:
            VStack(alignment: .leading) {
                Text("Microphone access is off, so voice-follow can't run.")
                    .foregroundStyle(.secondary)
                Button("Open System Settings", systemImage: "gear", action: openMicrophoneSettings)
            }
        }
    }

    private func openMicrophoneSettings() {
        guard
            let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
            )
        else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
