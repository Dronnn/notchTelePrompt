//
//  PreferencesView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// root of the preferences window: a sidebar of panes with the selected pane shown in the detail column.
/// NavigationSplitView is used instead of the Tab API, which needs macOS 15.
struct PreferencesView: View {
    let preferencesStore: PreferencesStore
    let scriptStore: ScriptStore
    /// invoked by the privacy pane; the actual work lives in the app delegate.
    var onExportAllScripts: () -> Void = {}
    var onClearLocalData: () -> Void = {}

    @State private var selection: PreferencePane = .general

    var body: some View {
        NavigationSplitView {
            List(PreferencePane.allCases, selection: $selection) { pane in
                Label(pane.title, systemImage: pane.systemImage)
                    .tag(pane)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            PreferenceDetailView(
                pane: selection,
                preferencesStore: preferencesStore,
                scriptStore: scriptStore,
                onExportAllScripts: onExportAllScripts,
                onClearLocalData: onClearLocalData
            )
        }
        .frame(minWidth: 460, minHeight: 360)
    }
}

/// shows the pane matching the current selection; kept as its own struct so the detail content has a
/// reasonable min size without breaking the view into a computed property.
private struct PreferenceDetailView: View {
    let pane: PreferencePane
    let preferencesStore: PreferencesStore
    let scriptStore: ScriptStore
    let onExportAllScripts: () -> Void
    let onClearLocalData: () -> Void

    var body: some View {
        Group {
            switch pane {
            case .general:
                GeneralSettingsView(preferencesStore: preferencesStore)
            case .prompter:
                PrompterSettingsView(preferencesStore: preferencesStore)
            case .voice:
                VoiceSettingsView(preferencesStore: preferencesStore)
            case .shortcuts:
                ShortcutsSettingsView()
            case .privacy:
                PrivacySettingsView(
                    onExportAllScripts: onExportAllScripts,
                    onClearLocalData: onClearLocalData
                )
            }
        }
        .frame(minWidth: 280, minHeight: 320)
    }
}
