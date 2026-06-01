//
//  DockIconPolicy.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit

/// applies the app's Dock-visibility preference by switching the activation policy.
/// the app ships as an accessory (no Dock icon); .regular brings the icon back on demand.
@MainActor
enum DockIconPolicy {
    static func apply(showDockIcon: Bool) {
        NSApplication.shared.setActivationPolicy(showDockIcon ? .regular : .accessory)
    }
}
