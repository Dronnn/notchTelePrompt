//
//  AppLocalization.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// resolves app-owned strings in the language selected in preferences. reading the language from
/// UserDefaults keeps AppKit and model code consistent with the SwiftUI locale without a store reference.
nonisolated enum AppLocalization {
    /// the language currently selected in preferences.
    static var language: AppLanguage {
        AppLanguage.current
    }

    /// resolves a string from the selected language's compiled string table.
    static func string(_ key: String.LocalizationValue) -> String {
        string(key, language: language)
    }

    /// resolves a string for an explicit language; used by tests and by code that already has a language.
    static func string(_ key: String.LocalizationValue, language: AppLanguage) -> String {
        String(localized: key, bundle: language.bundle, locale: language.locale)
    }
}
