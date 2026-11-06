//
//  PrivacySettingsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the privacy pane of preferences: explains that everything stays local, and offers data management.
/// the actual export/clear work lives in the app delegate; this view just invokes the wired closures.
struct PrivacySettingsView: View {
    let onExportAllScripts: () -> Void
    let onClearLocalData: () -> Void

    var body: some View {
        Form {
            Section("Your data") {
                Text(
                    "Your scripts and any voice analysis stay on this Mac. "
                        + "Nothing is uploaded: there is no account and no analytics."
                )
                .foregroundStyle(.secondary)
            }

            Section("Screen capture") {
                Text(
                    "NotchPrompter requests capture exclusion for all its windows, but macOS and sharing apps "
                        + "may still capture them. Share a specific application window and check your recording setup."
                )
                .foregroundStyle(.secondary)
            }

            Section("Manage") {
                Button("Export All Scripts…", action: onExportAllScripts)
                Button("Clear Local Data…", role: .destructive, action: onClearLocalData)
            }
        }
        .formStyle(.grouped)
    }
}
