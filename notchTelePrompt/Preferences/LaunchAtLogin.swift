//
//  LaunchAtLogin.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import OSLog
import ServiceManagement

/// thin wrapper over SMAppService.mainApp for the "launch at login" preference.
/// reads the real system status and registers/unregisters without ever force-trying.
@MainActor
enum LaunchAtLogin {
    private static let logger = Logger(subsystem: "com.notchTelePrompt", category: "LaunchAtLogin")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// registers or unregisters the login item. on failure (including pending approval) it sends the
    /// user to the Login Items pane so they can resolve it manually; the toggle should then re-read isEnabled.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            if SMAppService.mainApp.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch {
            logger.error("failed to update launch-at-login: \(error.localizedDescription, privacy: .public)")
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
