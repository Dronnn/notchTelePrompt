//
//  CountdownOption.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

/// pre-start countdown durations offered by the prompter (spec §17): off, 3, 5 or 10 seconds.
nonisolated enum CountdownOption: CaseIterable {
    case off
    case three
    case five
    case ten

    /// whole seconds to count down, or nil when the countdown is off.
    var seconds: Int? {
        switch self {
        case .off:
            nil
        case .three:
            3
        case .five:
            5
        case .ten:
            10
        }
    }

    // MARK: - Persistence

    /// the sentinel persisted for .off, distinct from any real duration.
    private static let offSentinel = -1

    /// a stable Int for UserDefaults: the seconds for a real countdown, or a sentinel for .off.
    var persistedValue: Int {
        seconds ?? Self.offSentinel
    }

    /// reverses persistedValue, falling back to .off for the sentinel or any unknown value.
    init(persistedValue: Int) {
        self = Self.allCases.first { $0.seconds == persistedValue } ?? .off
    }
}
