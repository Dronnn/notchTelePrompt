//
//  PrompterContentView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// prompter rendering: the current script text on a translucent dark background, with a subtle progress
/// bar and the countdown / voice overlays. the top-right control row is not here: it lives in a separate
/// top-most hosting view (see PrompterControlsView) so it can never be hidden by the scroll-catcher's
/// native subview inside the text view.
struct PrompterContentView: View {
    let viewModel: PrompterViewModel

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
