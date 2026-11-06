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
    func selectedLanguagePersistsAndRecordsTheSystemOverride() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = PreferencesStore(defaults: defaults)
        #expect(preferences.appLanguage == .system)

        preferences.appLanguage = .russian
        #expect(defaults.string(forKey: AppLanguage.defaultsKey) == "ru")
        #expect(defaults.stringArray(forKey: "AppleLanguages") == ["ru"])

        let restored = PreferencesStore(defaults: defaults)
        #expect(restored.appLanguage == .russian)
    }

    @Test
    func switchingBackToSystemPersistsTheSystemSelection() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = PreferencesStore(defaults: defaults)
        preferences.showDockIcon = true
        defaults.set(["ru"], forKey: "AppleLanguages")
        preferences.appLanguage = .german
        preferences.appLanguage = .system

        #expect(defaults.string(forKey: AppLanguage.defaultsKey) == "system")
        #expect(defaults.persistentDomain(forName: suite)?["AppleLanguages"] == nil)
        #expect(defaults.bool(forKey: "preferences.showDockIcon"))
    }

    @Test
    func changingTheLanguagePostsALiveUpdateNotification() async throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = PreferencesStore(defaults: defaults)

        await confirmation("language change posts a notification") { confirm in
            let token = NotificationCenter.default.addObserver(
                forName: .appLanguageDidChange,
                object: nil,
                queue: nil
            ) { _ in
                confirm()
            }
            preferences.appLanguage = .french
            NotificationCenter.default.removeObserver(token)
        }
    }

    @Test
    func everyLanguageHasALocale() {
        #expect(!AppLanguage.system.locale.identifier.isEmpty)
        #expect(AppLanguage.english.locale.identifier == "en")
        #expect(AppLanguage.german.locale.identifier == "de")
        #expect(AppLanguage.french.locale.identifier == "fr")
        #expect(AppLanguage.spanish.locale.identifier == "es")
        #expect(AppLanguage.brazilianPortuguese.locale.identifier == "pt-BR")
        #expect(AppLanguage.russian.locale.identifier == "ru")
    }
}
