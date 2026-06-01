//
//  DropConfirmationState.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// the pending drop payload held while the new-vs-replace confirmation dialog is shown.
/// stored as an Optional on ImportExportViewModel so the confirmation state stays explicit and testable.
struct DropConfirmationState {
    let url: URL
    let title: String
    let text: String
}
