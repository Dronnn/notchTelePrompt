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
}
