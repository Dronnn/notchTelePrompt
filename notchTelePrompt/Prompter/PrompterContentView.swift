//
//  PrompterContentView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// prompter rendering: the current script text on a translucent dark background,
/// with a subtle progress bar and an always-visible control row in the top-right corner.
struct PrompterContentView: View {
    let viewModel: PrompterViewModel
    let onClose: () -> Void
    let onSnap: () -> Void
    let onToggleNavigator: () -> Void
    let onToggleControlPanel: () -> Void
    let onToggleLibrary: () -> Void
    let onTogglePreferences: () -> Void

    var body: some View {
        PrompterBodyView(viewModel: viewModel)
            .background(.black.opacity(viewModel.backgroundOpacity))
            .overlay {
                if viewModel.scrollEngine.state == .countdown {
                    PrompterCountdownOverlay(secondsRemaining: viewModel.scrollEngine.countdownRemaining)
                }
            }
            .overlay(alignment: .bottom) {
                PrompterProgressBar(progress: viewModel.progress)
            }
            .overlay(alignment: .topTrailing) {
                PrompterControlsView(
                    viewModel: viewModel,
                    onClose: onClose,
                    onSnap: onSnap,
                    onToggleNavigator: onToggleNavigator,
                    onToggleControlPanel: onToggleControlPanel,
                    onToggleLibrary: onToggleLibrary,
                    onTogglePreferences: onTogglePreferences
                )
            }
            .overlay(alignment: .topLeading) {
                if viewModel.isVoiceModeEnabled {
                    PrompterVoiceIndicatorView(isSpeaking: viewModel.isSpeaking)
                        .padding(8)
                }
            }
            .clipShape(.rect(cornerRadius: 8))
            .onHover { hovering in
                viewModel.setHovering(hovering)
            }
    }
}

/// the prompter's text body: the scrollable line rendering when a script is loaded,
/// or a centered placeholder when none is selected.
private struct PrompterBodyView: View {
    let viewModel: PrompterViewModel

    var body: some View {
        if viewModel.currentScript == nil {
            Text("No script selected.")
                .foregroundStyle(viewModel.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            PrompterTextView(viewModel: viewModel)
        }
    }
}

/// the always-visible control row over the prompter: playback, font size, the window toggles
/// (set navigator, mini controls, library, preferences), snap-to-notch and close.
private struct PrompterControlsView: View {
    let viewModel: PrompterViewModel
    let onClose: () -> Void
    let onSnap: () -> Void
    let onToggleNavigator: () -> Void
    let onToggleControlPanel: () -> Void
    let onToggleLibrary: () -> Void
    let onTogglePreferences: () -> Void

    private var isPlaying: Bool {
        viewModel.scrollEngine.state == .playing
    }

    var body: some View {
        HStack {
            Button(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill") {
                viewModel.playPause()
            }
            Button("Restart", systemImage: "arrow.counterclockwise") {
                viewModel.restart()
            }
            Button("Slower", systemImage: "tortoise") {
                viewModel.decreaseSpeed()
            }
            Button("Faster", systemImage: "hare") {
                viewModel.increaseSpeed()
            }
            Button("Smaller text", systemImage: "textformat.size.smaller") {
                viewModel.decreaseFontSize()
            }
            .disabled(!viewModel.canDecreaseFontSize)
            Button("Larger text", systemImage: "textformat.size.larger") {
                viewModel.increaseFontSize()
            }
            .disabled(!viewModel.canIncreaseFontSize)
            Button("Set Navigator", systemImage: "sidebar.left") { onToggleNavigator() }
            Button("Mini Controls", systemImage: "slider.horizontal.3") { onToggleControlPanel() }
            Button("Library", systemImage: "books.vertical") { onToggleLibrary() }
            Button("Preferences", systemImage: "gearshape") { onTogglePreferences() }
            Button("Snap to Notch", systemImage: "arrow.up.to.line", action: onSnap)
            Button("Close", systemImage: "xmark", action: onClose)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.9))
        .padding(8)
        .background(.black.opacity(0.55), in: .rect(cornerRadius: 8))
        .padding(6)
    }
}
