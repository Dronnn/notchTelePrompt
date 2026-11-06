//
//  PreferencePaneTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

@testable import notchTelePrompt
import Testing

@MainActor
struct PreferencePaneTests {
    @Test
    func supportIsItsOwnPreferencePane() {
        #expect(PreferencePane.allCases.contains(.support))
        #expect(PreferencePane.support.rawValue == "support")
    }

    @Test
    func everyPaneHasADistinctIdentity() {
        let identifiers = PreferencePane.allCases.map(\.id)
        #expect(Set(identifiers).count == identifiers.count)
    }
}
