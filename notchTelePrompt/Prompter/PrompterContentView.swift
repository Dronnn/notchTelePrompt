//
//  PrompterContentView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// prompter rendering: the current script text on a translucent dark background,
/// with a subtle progress bar and close / snap-to-notch controls that fade in on hover.
struct PrompterContentView: View {
    let viewModel: PrompterViewModel
    let onClose: () -> Void
    let onSnap: () -> Void

    @State private var isHovering = false

    var body: some View {
        PrompterBodyView(viewModel: viewModel)
            .background(.black.opacity(0.82))
            .overlay {
                if viewModel.scrollEngine.state == .countdown {
                    PrompterCountdownOverlay(secondsRemaining: viewModel.scrollEngine.countdownRemaining)
                }
            }
            .overlay(alignment: .bottom) {
                PrompterProgressBar(progress: viewModel.progress)
            }
            .overlay(alignment: .topTrailing) {
                PrompterControlsView(viewModel: viewModel, onClose: onClose, onSnap: onSnap)
                    .opacity(isHovering ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
            .clipShape(.rect(cornerRadius: 8))
            .onHover { hovering in
                isHovering = hovering
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            PrompterTextView(viewModel: viewModel)
        }
    }
}

/// the subtle hover-revealed control row over the prompter text: font size, snap-to-notch and close.
private struct PrompterControlsView: View {
    let viewModel: PrompterViewModel
    let onClose: () -> Void
    let onSnap: () -> Void

    private var isPlaying: Bool {
        viewModel.scrollEngine.state == .playing
    }

    var body: some View {
        HStack {
            Button(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill") {
                viewModel.togglePlayPause()
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
            .disabled(viewModel.fontSize <= PrompterFontSize.min)
            Button("Larger text", systemImage: "textformat.size.larger") {
                viewModel.increaseFontSize()
            }
            .disabled(viewModel.fontSize >= PrompterFontSize.max)
            Button("Snap to Notch", systemImage: "arrow.up.to.line", action: onSnap)
            Button("Close", systemImage: "xmark", action: onClose)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
        .padding(8)
    }
}
