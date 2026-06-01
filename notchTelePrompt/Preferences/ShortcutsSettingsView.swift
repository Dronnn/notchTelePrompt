//
//  ShortcutsSettingsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import KeyboardShortcuts
import SwiftUI

/// the shortcuts pane of preferences: rebindable global-hotkey recorders.
/// KeyboardShortcuts persists every binding to UserDefaults, so no save action is needed here.
struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Prompter") {
                KeyboardShortcuts.Recorder("Show / Hide Prompter", name: .togglePrompter)
                KeyboardShortcuts.Recorder("Start / Pause", name: .startPausePrompter)
                KeyboardShortcuts.Recorder("Restart", name: .restartPrompter)
                KeyboardShortcuts.Recorder("Speed Up", name: .speedUpPrompter)
                KeyboardShortcuts.Recorder("Speed Down", name: .speedDownPrompter)
            }

            Section("Navigation") {
                KeyboardShortcuts.Recorder("Next Script", name: .nextScript)
                KeyboardShortcuts.Recorder("Previous Script", name: .previousScript)
                KeyboardShortcuts.Recorder("Open Editor", name: .openEditor)
            }

            Section {
                Button("Restore Defaults", systemImage: "arrow.counterclockwise") {
                    KeyboardShortcuts.reset(
                        .togglePrompter,
                        .startPausePrompter,
                        .restartPrompter,
                        .speedUpPrompter,
                        .speedDownPrompter,
                        .nextScript,
                        .previousScript,
                        .openEditor
                    )
                }
            }
        }
        .formStyle(.grouped)
    }
}
