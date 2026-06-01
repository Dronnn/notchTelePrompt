//
//  PrompterViewModelTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import SwiftData
import Testing

@MainActor
struct PrompterViewModelTests {
    /// builds a fresh in-memory store with a single script for each test so cases stay isolated.
    /// countdown is driven through an isolated PreferencesStore, since the view model now reads it there.
    private func makeViewModelWithScript() throws -> (PrompterViewModel, Script, PreferencesStore) {
        let container = try ModelContainerFactory.makeInMemory()
        let store = ScriptStore(container: container)
        let script = try store.create(title: "T", text: "line one\nline two\nline three")
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let preferences = PreferencesStore(defaults: defaults)
        preferences.countdown = .off
        let viewModel = PrompterViewModel(store: store, preferences: preferences)
        viewModel.currentScript = script
        return (viewModel, script, preferences)
    }

    // MARK: - Play / pause

    @Test
    func playPauseFromIdleStartsPlayingWhenCountdownOff() throws {
        let (viewModel, _, _) = try makeViewModelWithScript()
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
    }

    @Test
    func playPauseTogglesPauseThenResume() throws {
        let (viewModel, _, _) = try makeViewModelWithScript()
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .paused)
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
    }

    @Test
    func playPauseIgnoresEmptyScript() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = ScriptStore(container: container)
        let script = try store.create(title: "Empty", text: "   \n  ")
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let preferences = PreferencesStore(defaults: defaults)
        preferences.countdown = .off
        let viewModel = PrompterViewModel(store: store, preferences: preferences)
        viewModel.currentScript = script
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .idle)
    }

    // MARK: - Countdown

    @Test
    func playPauseFromIdleEntersCountdownWhenConfigured() throws {
        let (viewModel, _, preferences) = try makeViewModelWithScript()
        preferences.countdown = .three
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .countdown)
    }

    @Test
    func playPauseIsNoOpDuringCountdown() throws {
        let (viewModel, _, preferences) = try makeViewModelWithScript()
        preferences.countdown = .three
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .countdown)
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .countdown)
    }

    // MARK: - Stop

    @Test
    func stopReturnsToIdleAndTop() throws {
        let (viewModel, _, _) = try makeViewModelWithScript()
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
        viewModel.stop()
        #expect(viewModel.scrollEngine.state == .idle)
        #expect(viewModel.scrollEngine.offset == 0)
    }

    // MARK: - Font size

    @Test
    func decreaseFontSizeLowersStoredDefaultByOneStep() throws {
        let (viewModel, _, preferences) = try makeViewModelWithScript()
        preferences.prompterDefaults.fontSize = 28
        viewModel.decreaseFontSize()
        #expect(preferences.prompterDefaults.fontSize == 26)
    }

    @Test
    func increaseFontSizeRaisesStoredDefaultByOneStep() throws {
        let (viewModel, _, preferences) = try makeViewModelWithScript()
        preferences.prompterDefaults.fontSize = 28
        viewModel.increaseFontSize()
        #expect(preferences.prompterDefaults.fontSize == 30)
    }

    @Test
    func canDecreaseFontSizeReflectsLowerBound() throws {
        let (viewModel, _, preferences) = try makeViewModelWithScript()
        preferences.prompterDefaults.fontSize = PrompterFontSize.min
        #expect(viewModel.canDecreaseFontSize == false)
        preferences.prompterDefaults.fontSize = PrompterFontSize.min + PrompterFontSize.step
        #expect(viewModel.canDecreaseFontSize == true)
    }

    @Test
    func canIncreaseFontSizeReflectsUpperBound() throws {
        let (viewModel, _, preferences) = try makeViewModelWithScript()
        preferences.prompterDefaults.fontSize = PrompterFontSize.max
        #expect(viewModel.canIncreaseFontSize == false)
        preferences.prompterDefaults.fontSize = PrompterFontSize.max - PrompterFontSize.step
        #expect(viewModel.canIncreaseFontSize == true)
    }
}
