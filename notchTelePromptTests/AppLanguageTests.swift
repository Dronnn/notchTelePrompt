//
//  AppLanguageTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

@MainActor
struct AppLanguageTests {
    @Test
    func selectedLanguagePersistsAsAnAppLanguageOverride() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = PreferencesStore(defaults: defaults)
        #expect(preferences.appLanguage == .system)
        #expect(!preferences.requiresLanguageRestart)

        preferences.appLanguage = .brazilianPortuguese
        #expect(defaults.stringArray(forKey: "AppleLanguages") == ["pt-BR"])
        #expect(preferences.requiresLanguageRestart)

        let restored = PreferencesStore(defaults: defaults)
        #expect(restored.appLanguage == .brazilianPortuguese)
        #expect(!restored.requiresLanguageRestart)
    }

    @Test
    func systemDefaultRemovesOnlyTheAppLanguageOverride() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = PreferencesStore(defaults: defaults)
        preferences.showDockIcon = true
        preferences.appLanguage = .german
        preferences.appLanguage = .system

        #expect(defaults.persistentDomain(forName: suite)?["AppleLanguages"] == nil)
        #expect(defaults.bool(forKey: "preferences.showDockIcon"))
        #expect(!preferences.requiresLanguageRestart)
    }
}
