//
//  PrompterVisibilityStoreTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

@MainActor
struct PrompterVisibilityStoreTests {
    /// fresh, isolated defaults suite per store so cases never bleed into one another.
    private func makeStore() throws -> PrompterVisibilityStore {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        return PrompterVisibilityStore(defaults: defaults)
    }

    @Test
    func defaultVisibilityIsFalse() throws {
        let store = try makeStore()
        #expect(store.isVisible == false)
    }

    @Test
    func setVisibleTruePersists() throws {
        let store = try makeStore()
        store.setVisible(true)
        #expect(store.isVisible == true)
    }

    @Test
    func setVisibleFalsePersists() throws {
        let store = try makeStore()
        store.setVisible(true)
        store.setVisible(false)
        #expect(store.isVisible == false)
    }

    @Test
    func toggleFlipsFromFalseToTrue() throws {
        let store = try makeStore()
        store.toggle()
        #expect(store.isVisible == true)
    }

    @Test
    func toggleFlipsFromTrueToFalse() throws {
        let store = try makeStore()
        store.setVisible(true)
        store.toggle()
        #expect(store.isVisible == false)
    }

    // MARK: - Size

    @Test
    func defaultSizeIsNil() throws {
        let store = try makeStore()
        #expect(store.size == nil)
    }

    @Test
    func setSizePersistsAndReadsBack() throws {
        let store = try makeStore()
        let size = CGSize(width: 720, height: 160)
        store.setSize(size)
        #expect(store.size == size)
    }

    @Test
    func nonPositiveDimensionsReadBackAsNil() throws {
        let store = try makeStore()
        store.setSize(CGSize(width: 0, height: 200))
        #expect(store.size == nil)
        store.setSize(CGSize(width: 200, height: -10))
        #expect(store.size == nil)
    }
}
