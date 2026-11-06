//
//  ImportExportError.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// the failure paths across import, export and clipboard.
/// surfaced through ImportExportViewModel.errorMessage; descriptions match the spec §39 style.
enum ImportExportError: LocalizedError {
    case noTextInClipboard
    case unreadableFile(underlying: Error)
    case unencodableText
    case exportFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .noTextInClipboard:
            AppLocalization.string("Clipboard does not contain text.")
        case let .unreadableFile(underlying):
            AppLocalization.string("This file couldn't be read. \(underlying.localizedDescription)")
        case .unencodableText:
            AppLocalization.string("This text couldn't be read as UTF-8.")
        case let .exportFailed(underlying):
            AppLocalization.string("The file couldn't be written. \(underlying.localizedDescription)")
        }
    }
}
