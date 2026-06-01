//
//  PrompterSettingsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// placeholder for the prompter defaults pane; the real controls land in a later phase.
struct PrompterSettingsView: View {
    let preferencesStore: PreferencesStore

    var body: some View {
        Form {
            Text("Prompter settings — coming up.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
