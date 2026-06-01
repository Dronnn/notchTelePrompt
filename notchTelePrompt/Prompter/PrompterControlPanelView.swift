//
//  PrompterControlPanelView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the mini control panel's content: a single horizontal row of icon-only playback controls
/// on a translucent dark rounded background, mirroring the prompter overlay's control styling.
struct PrompterControlPanelView: View {
    let viewModel: PrompterViewModel
    let onTogglePrompter: () -> Void

    private var isPlaying: Bool {
        viewModel.scrollEngine.state == .playing
    }

    private var hasScript: Bool {
        viewModel.currentScript != nil
    }

    private var voiceSymbol: String {
        guard viewModel.isVoiceModeEnabled else {
            return "mic.slash"
        }
        return viewModel.isSpeaking ? "mic.fill" : "mic"
    }

    var body: some View {
        HStack {
            Button(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill") {
                viewModel.playPause()
            }
            .disabled(!hasScript)
            Button("Restart", systemImage: "arrow.counterclockwise") {
                viewModel.restart()
            }
            .disabled(!hasScript)
            Button("Slower", systemImage: "tortoise") {
                viewModel.decreaseSpeed()
            }
            .disabled(!hasScript)
            Button("Faster", systemImage: "hare") {
                viewModel.increaseSpeed()
            }
            .disabled(!hasScript)
            Button("Smaller text", systemImage: "textformat.size.smaller") {
                viewModel.decreaseFontSize()
            }
            .disabled(!viewModel.canDecreaseFontSize)
            Button("Larger text", systemImage: "textformat.size.larger") {
                viewModel.increaseFontSize()
            }
            .disabled(!viewModel.canIncreaseFontSize)
            Button(
                viewModel.isVoiceModeEnabled ? "Voice on" : "Voice off",
                systemImage: voiceSymbol
            ) {
                viewModel.toggleVoiceMode()
            }
            Button(
                viewModel.isOverlayVisible ? "Hide Prompter" : "Show Prompter",
                systemImage: viewModel.isOverlayVisible ? "eye.slash" : "eye",
                action: onTogglePrompter
            )
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.82))
        .clipShape(.rect(cornerRadius: 8))
    }
}
