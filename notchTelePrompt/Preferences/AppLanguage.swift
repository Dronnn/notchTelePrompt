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

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .system: String(localized: "System default")
        case .english: "English"
        case .german: "Deutsch"
        case .french: "Français"
        case .spanish: "Español"
        case .brazilianPortuguese: "Português (Brasil)"
        case .russian: "Русский"
        }
    }
}
