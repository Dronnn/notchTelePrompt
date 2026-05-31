//
//  WelcomeView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// first-launch onboarding: introduces the app and lets the user pick a display mode.
struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("displayMode") private var displayMode = PrompterDisplayMode.notch.rawValue

    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to NotchPrompter")
                .font(.title)
                .bold()

            Text("Your teleprompter, displayed near the camera so you can keep eye contact.")
                .foregroundStyle(.secondary)

            Picker("Display mode", selection: $displayMode) {
                Text("Around the notch").tag(PrompterDisplayMode.notch.rawValue)
                Text("Top overlay").tag(PrompterDisplayMode.topOverlay.rawValue)
            }
            .pickerStyle(.radioGroup)

            Spacer()

            Button("Get Started") {
                hasSeenWelcome = true
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(minWidth: 360, minHeight: 240)
    }
}

#Preview {
    WelcomeView()
}
