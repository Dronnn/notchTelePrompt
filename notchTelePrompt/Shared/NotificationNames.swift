//
//  NotificationNames.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

extension Notification.Name {
    /// posted when the script editor's text surface appears or is replaced, so the main window can
    /// reapply its Finder drop-target configuration to the newly created NSTextView.
    static let scriptEditorDidAppear = Notification.Name("scriptEditorDidAppear")
}
