//
//  LocalizationTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct LocalizationTests {
    private static let translatedLanguages = ["de", "fr", "es", "pt-BR", "ru"]

    @Test
    func catalogHasEveryTranslation() throws {
        let catalogURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "notchTelePrompt/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(catalog["strings"] as? [String: Any])

        for language in Self.translatedLanguages {
            for key in strings.keys {
                let entry = strings[key] as? [String: Any]
                let localizations = entry?["localizations"] as? [String: Any]
                #expect(localizations?[language] != nil, "missing \(language) translation for \(key)")
            }
        }
    }

    @Test
    func compiledBundlesResolveEveryLanguage() {
        #expect(AppLocalization.string("Cancel", language: .german) == "Abbrechen")
        #expect(AppLocalization.string("Cancel", language: .french) == "Annuler")
        #expect(AppLocalization.string("Cancel", language: .spanish) == "Cancelar")
        #expect(AppLocalization.string("Cancel", language: .brazilianPortuguese) == "Cancelar")
        #expect(AppLocalization.string("Cancel", language: .russian) == "Отмена")
    }

    @Test
    func russianPluralRulesResolve() {
        #expect(AppLocalization.string("\(1) words", language: .russian) == "1 слово")
        #expect(AppLocalization.string("\(3) words", language: .russian) == "3 слова")
        #expect(AppLocalization.string("\(5) words", language: .russian) == "5 слов")
        #expect(AppLocalization.string("\(21) words", language: .russian) == "21 слово")
    }
}
