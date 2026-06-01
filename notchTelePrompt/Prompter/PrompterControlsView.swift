//
//  PrompterControlsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the always-visible control row over the prompter: playback, voice-follow, font size, the window toggles
/// (set navigator, mini controls, library, preferences), snap-to-notch and close.
///
/// hosted in its own top-most hosting view pinned to the top-right corner (see PrompterWindowController):
/// the scroll-catcher inside the text view is an nsviewrepresentable, which appkit composites as a native
/// subview above any sibling swiftui overlay in the same host and so hid this row. a separate host sized to
/// the pill keeps the row visible and leaves the rest of the window free for scroll / drag.
struct PrompterControlsView: View {
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
            Button(
                viewModel.isVoiceModeEnabled ? "Stop voice follow" : "Start voice follow",
                systemImage: viewModel.isVoiceModeEnabled ? "mic.fill" : "mic.slash"
            ) {
                viewModel.toggleVoiceMode()
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
