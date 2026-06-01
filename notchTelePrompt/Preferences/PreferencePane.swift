//
//  PreferencePane.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the panes of the preferences window, used both for the sidebar list and the detail switch.
enum PreferencePane: String, CaseIterable, Identifiable {
    case general
    case prompter
    case voice
    case shortcuts
    case privacy

    var id: String {
        rawValue
    }

    var title: LocalizedStringKey {
        switch self {
        case .general: "General"
        case .prompter: "Prompter"
        case .voice: "Voice"
        case .shortcuts: "Shortcuts"
        case .privacy: "Privacy"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gear"
        case .prompter: "textformat"
        case .voice: "mic"
        case .shortcuts: "command"
        case .privacy: "lock.shield"
        }
    }
}
