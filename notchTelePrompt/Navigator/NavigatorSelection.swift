//
//  NavigatorSelection.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// pure index math for moving the navigator's selection between adjacent scripts.
/// clamps at the ends (no wrap) and is safe on an empty list, so the logic can be unit-tested
/// without the view model, store, or any actor isolation.
nonisolated enum NavigatorSelection {
    /// the index after `current`, clamped to the last valid index; nil when the list is empty.
    /// nil `current` (no selection yet) advances to the first item.
    static func nextIndex(after current: Int?, count: Int) -> Int? {
        guard count > 0 else {
            return nil
        }
        guard let current else {
            return 0
        }
        return min(current + 1, count - 1)
    }

    /// the index before `current`, clamped to zero; nil when the list is empty.
    /// nil `current` (no selection yet) moves to the first item.
    static func previousIndex(before current: Int?, count: Int) -> Int? {
        guard count > 0 else {
            return nil
        }
        guard let current else {
            return 0
        }
        return max(current - 1, 0)
    }
}
