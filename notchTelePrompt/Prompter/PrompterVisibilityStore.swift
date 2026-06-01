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
    static let widthKey = "prompterWidth"
    static let heightKey = "prompterHeight"

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

    // MARK: - Size

    /// the last user-set overlay size, or nil if none has been stored yet.
    var size: CGSize? {
        let width = defaults.double(forKey: Self.widthKey)
        let height = defaults.double(forKey: Self.heightKey)
        guard width > 0, height > 0 else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    func setSize(_ size: CGSize) {
        defaults.set(size.width, forKey: Self.widthKey)
        defaults.set(size.height, forKey: Self.heightKey)
    }
}
