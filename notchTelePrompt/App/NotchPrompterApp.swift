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
        // the app is a menu-bar app: the app delegate owns every window, including preferences.
        // the settings scene only hosts a fallback copy of the preferences content so an accidental
        // system request never shows an empty window. the standard Settings item is replaced below so
        // ⌘, opens the same PreferencesWindowController instance as the gear and the menu bar item.
        Settings {
            PreferencesView(
                preferencesStore: appDelegate.environment.preferencesStore,
                scriptStore: appDelegate.environment.scriptStore,
                tipStore: appDelegate.environment.tipStore,
                onExportAllScripts: { appDelegate.exportAllScripts() },
                onClearLocalData: { appDelegate.confirmAndClearLocalData() }
            )
        }
        .modelContainer(appDelegate.environment.modelContainer)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    appDelegate.showPreferences()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
