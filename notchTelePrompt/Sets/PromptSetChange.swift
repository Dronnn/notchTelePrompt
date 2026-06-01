//
//  PromptSetChange.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// broadcast when a prompt set's contents or order change, so the main-window sets editor and the
/// floating navigator stay in sync without holding references to each other. userInfo carries the set id.
extension Notification.Name {
    static let promptSetDidChange = Notification.Name("promptSetDidChange")
}

/// userInfo key for the changed set's id on a promptSetDidChange notification.
nonisolated enum PromptSetChange {
    static let setIDKey = "promptSetID"
}
