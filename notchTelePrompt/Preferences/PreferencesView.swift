//
//  PreferencesView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// root of the preferences window. for now it hosts only the shortcuts pane;
/// a later phase adds more panes (e.g. general, appearance) alongside it.
struct PreferencesView: View {
    var body: some View {
        ShortcutsSettingsView()
            .frame(minWidth: 460, minHeight: 360)
    }
}
