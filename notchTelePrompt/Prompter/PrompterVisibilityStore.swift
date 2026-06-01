//
//  PrompterVisibilityStore.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// reads and writes the prompter's last-visibility flag in a given UserDefaults suite.
/// taking the defaults as a dependency keeps the type pure and isolation-free for unit tests.
struct PrompterVisibilityStore {
    static let visibilityKey = "prompterIsVisible"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// defaults to false when no value has been written yet.
    var isVisible: Bool {
        defaults.bool(forKey: Self.visibilityKey)
    }

    func setVisible(_ visible: Bool) {
        defaults.set(visible, forKey: Self.visibilityKey)
    }

    func toggle() {
        setVisible(!isVisible)
    }
}
