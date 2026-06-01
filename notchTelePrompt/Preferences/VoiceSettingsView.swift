//
//  VoiceSettingsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// placeholder for the voice-follow pane; the real controls land in a later phase.
struct VoiceSettingsView: View {
    let preferencesStore: PreferencesStore

    var body: some View {
        Form {
            Text("Voice settings — coming up.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
