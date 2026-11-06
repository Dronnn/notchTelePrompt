//
//  TipFeedback.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// transient feedback shown after a tip purchase. cancellation stays silent, so there is no case for it.
enum TipFeedback: Equatable, Sendable {
    case pending
    case thankYou
    case failed
}
