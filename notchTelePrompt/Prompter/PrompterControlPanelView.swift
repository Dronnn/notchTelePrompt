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
    let onHidePrompter: () -> Void

    private var isPlaying: Bool {
        viewModel.scrollEngine.state == .playing
    }

    private var hasScript: Bool {
        viewModel.currentScript != nil
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
            Button("Hide Prompter", systemImage: "eye.slash", action: onHidePrompter)
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
