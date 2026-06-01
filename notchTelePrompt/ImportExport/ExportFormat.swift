//
//  ExportFormat.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

/// the supported export file formats, with their file extensions and uniform type identifiers.
/// shared by ScriptTextCore and ImportExportService.
enum ExportFormat: CaseIterable {
    case txt
    case md

    var fileExtension: String {
        switch self {
        case .txt: "txt"
        case .md: "md"
        }
    }

    /// resolving by filename extension is more reliable than the reverse-DNS markdown identifier,
    /// which can be unavailable on some macOS 14 configurations. plain text is a safe fallback.
    var utType: UTType {
        switch self {
        case .txt: .plainText
        case .md: UTType(filenameExtension: "md") ?? .plainText
        }
    }

    var localizedLabel: String {
        switch self {
        case .txt: String(localized: "Plain Text (.txt)")
        case .md: String(localized: "Markdown (.md)")
        }
    }
}
