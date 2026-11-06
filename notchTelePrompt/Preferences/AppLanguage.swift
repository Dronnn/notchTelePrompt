//
//  AppLanguage.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case brazilianPortuguese = "pt-BR"
    case russian = "ru"

    /// UserDefaults key shared by the preferences store and the live localization lookup.
    static let defaultsKey = "preferences.appLanguage"

    var id: String {
        rawValue
    }

    /// the language persisted in preferences, or the system language when none is selected.
    static var current: AppLanguage {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    /// the locale SwiftUI uses to resolve localized text and format values.
    var locale: Locale {
        switch self {
        case .system: Self.systemLocale
        default: Locale(identifier: rawValue)
        }
    }

    /// the OS language, ignoring a stale per-app override written by older app versions.
    /// a genuine system per-app language is honoured while the app itself is set to system.
    private static var systemLocale: Locale {
        if
            current == .system,
            let appLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages"),
            let first = appLanguages.first
        {
            return Locale(identifier: first)
        }
        let globalLanguages = UserDefaults.standard
            .persistentDomain(forName: "NSGlobalDomain")?["AppleLanguages"] as? [String]
        if let first = globalLanguages?.first {
            return Locale(identifier: first)
        }
        return .autoupdatingCurrent
    }

    /// the compiled string table for this language. resolving the `.lproj` explicitly keeps the
    /// selection independent of the process-wide AppleLanguages value loaded at launch.
    var bundle: Bundle {
        switch self {
        case .system: Self.bundle(for: Self.systemLocale.identifier)
        default: Self.bundle(for: rawValue)
        }
    }

    private static func bundle(for identifier: String) -> Bundle {
        let languageCode = identifier.split(separator: "-").first.map(String.init)
        let candidates = [identifier, languageCode, languageCode == "pt" ? "pt-BR" : nil]
        for code in candidates.compactMap(\.self) {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return Bundle.main.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }

    var title: String {
        switch self {
        case .system: AppLocalization.string("System default")
        case .english: "English"
        case .german: "Deutsch"
        case .french: "Français"
        case .spanish: "Español"
        case .brazilianPortuguese: "Português (Brasil)"
        case .russian: "Русский"
        }
    }
}
