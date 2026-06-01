//
//  NotificationObserverToken.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// owns a NotificationCenter block-observer token and removes it when released.
/// lets a @MainActor @Observable type register an observer without its own nonisolated deinit
/// touching the non-Sendable token: the token lives and dies with this box instead.
final class NotificationObserverToken {
    // nonisolated(unsafe): set once at init and only read in deinit; NotificationCenter.removeObserver
    // is thread-safe, so opting the non-Sendable token out of deinit isolation checking is safe.
    nonisolated(unsafe) let token: any NSObjectProtocol

    init(_ token: any NSObjectProtocol) {
        self.token = token
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}
