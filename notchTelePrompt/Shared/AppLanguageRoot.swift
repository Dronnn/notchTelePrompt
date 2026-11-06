//
//  AppLanguageRoot.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// applies the selected app language to a SwiftUI tree hosted outside the main window scene.
/// observing the store here means changing the language updates the hosted content immediately.
struct AppLanguageRoot<Content: View>: View {
    let preferencesStore: PreferencesStore
    @ViewBuilder let content: Content

    var body: some View {
        content.environment(\.locale, preferencesStore.appLanguage.locale)
    }
}
