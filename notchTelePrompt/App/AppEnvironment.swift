//
//  AppEnvironment.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import SwiftData

/// shared application-wide dependencies, created once at launch.
/// holds the SwiftData container and the script store the rest of the app reads from.
@MainActor
@Observable
final class AppEnvironment {
    let modelContainer: ModelContainer
    let scriptStore: ScriptStore
    let promptSetStore: PromptSetStore

    init() {
        do {
            let container = try ModelContainerFactory.makePersistent()
            modelContainer = container
            scriptStore = ScriptStore(container: container)
            promptSetStore = PromptSetStore(container: container)
        } catch {
            // the app cannot function without its data store; fail loudly during development.
            fatalError("failed to create model container: \(error)")
        }
    }
}
