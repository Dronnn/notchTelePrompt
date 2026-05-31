//
//  NotchPrompterApp.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftData
import SwiftUI

@main
struct NotchPrompterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // a settings scene gives the app a valid scene without opening a window at launch.
        // preferences content is added in phase 10.
        Settings {
            EmptyView()
        }
        .modelContainer(appDelegate.environment.modelContainer)
    }
}
