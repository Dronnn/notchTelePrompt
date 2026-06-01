//
//  PromptSet.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import SwiftData

/// a saved, reusable, ordered collection of existing scripts used to run a session.
/// scriptIDs is an ordered array of Script.id values (not a SwiftData relationship) so reordering is trivial
/// and scripts deleted from the library are handled by filtering missing ids when resolving the set.
@Model
final class PromptSet {
    var id = UUID()
    var name: String = ""
    var createdAt = Date.now
    var updatedAt = Date.now
    var scriptIDs: [UUID] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        scriptIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.scriptIDs = scriptIDs
    }
}
