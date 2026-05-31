//
//  ModelContainerFactory.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import SwiftData

/// builds the app's SwiftData container. the on-disk store lives in Application Support;
/// tests use an in-memory container via makeInMemory().
enum ModelContainerFactory {
    /// the schema is centralized so the app and tests stay in sync and future migrations have one source of truth.
    static let schema = Schema([Script.self])

    /// persistent container backed by Application Support.
    static func makePersistent() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// in-memory container for unit tests and previews.
    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
