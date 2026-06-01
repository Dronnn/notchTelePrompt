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
    private func makeViewModelWithScript() throws -> (PrompterViewModel, Script) {
        let container = try ModelContainerFactory.makeInMemory()
        let store = ScriptStore(container: container)
        let script = try store.create(title: "T", text: "line one\nline two\nline three")
        let viewModel = PrompterViewModel(store: store)
        viewModel.countdown = .off
        viewModel.currentScript = script
        return (viewModel, script)
    }

    // MARK: - Play / pause

    @Test
    func playPauseFromIdleStartsPlayingWhenCountdownOff() throws {
        let (viewModel, _) = try makeViewModelWithScript()
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
    }

    @Test
    func playPauseTogglesPauseThenResume() throws {
        let (viewModel, _) = try makeViewModelWithScript()
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .paused)
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
    }

    // MARK: - Countdown

    @Test
    func playPauseFromIdleEntersCountdownWhenConfigured() throws {
        let (viewModel, _) = try makeViewModelWithScript()
        viewModel.countdown = .three
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .countdown)
    }

    @Test
    func playPauseIsNoOpDuringCountdown() throws {
        let (viewModel, _) = try makeViewModelWithScript()
        viewModel.countdown = .three
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .countdown)
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .countdown)
    }

    // MARK: - Stop

    @Test
    func stopReturnsToIdleAndTop() throws {
        let (viewModel, _) = try makeViewModelWithScript()
        viewModel.playPause()
        #expect(viewModel.scrollEngine.state == .playing)
        viewModel.stop()
        #expect(viewModel.scrollEngine.state == .idle)
        #expect(viewModel.scrollEngine.offset == 0)
    }
}
