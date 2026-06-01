//
//  GeneralSettingsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the general pane of preferences: startup behavior (login item, Dock icon, what to open on launch).
/// launch-at-login is mirrored from the real SMAppService status; the rest bind straight to the store.
struct GeneralSettingsView: View {
    let preferencesStore: PreferencesStore

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch NotchPrompter at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.setEnabled(newValue)
                        // re-sync to the real status: registration can require approval or fail. isEnabled
                        // treats .requiresApproval as on, so a pending-approval registration stays on and
                        // resyncs to the same value the user set, firing no reverse onChange.
                        launchAtLogin = LaunchAtLogin.isEnabled
                    }

                Toggle("Show icon in the Dock", isOn: Bindable(preferencesStore).showDockIcon)
                    .onChange(of: preferencesStore.showDockIcon) { _, newValue in
                        DockIconPolicy.apply(showDockIcon: newValue)
                    }

                Toggle("Reopen the last prompter on launch", isOn: Bindable(preferencesStore).restoreLastScript)

                Toggle("Open the editor on launch", isOn: Bindable(preferencesStore).openEditorOnLaunch)
            }
        }
        .formStyle(.grouped)
    }
}
