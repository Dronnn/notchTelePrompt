//
//  PrompterVoiceIndicatorView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the subtle voice-follow indicator shown on the overlay only while voice mode is on: a mic glyph
/// that stays dim while listening and brightens when speech is detected (spec §9.4 — not a recording
/// light). reuses the overlay's white-on-dark control styling.
struct PrompterVoiceIndicatorView: View {
    let isSpeaking: Bool

    var body: some View {
        Image(systemName: isSpeaking ? "mic.fill" : "mic")
            .foregroundStyle(.white.opacity(isSpeaking ? 1 : 0.4))
            .animation(.easeInOut(duration: 0.15), value: isSpeaking)
            .accessibilityLabel(isSpeaking ? Text("Listening — speech detected") : Text("Listening"))
    }
}
