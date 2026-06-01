//
//  PrompterChromeView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the prompter's non-interactive chrome: the pre-roll countdown, the bottom progress bar, and the
/// voice-listening indicator. hosted in its own view above the text host (see PrompterWindowController),
/// because the scroll-catcher inside the text view is an nsviewrepresentable that appkit composites above
/// any sibling swiftui overlay in the same host — which would otherwise hide all of this. hit-testing is
/// off throughout, so wheel scrolling and clicks pass straight through to the text view beneath.
struct PrompterChromeView: View {
    let viewModel: PrompterViewModel

    var body: some View {
        Color.clear
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
            .allowsHitTesting(false)
    }
}
