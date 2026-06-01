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
            .overlay(alignment: .bottom) {
                PrompterProgressBar(progress: viewModel.progress)
            }
            .overlay(alignment: .topTrailing) {
                PrompterControlsView(onClose: onClose, onSnap: onSnap)
                    .opacity(isHovering ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
            .clipShape(.rect(cornerRadius: 8))
            .onHover { isHovering = $0 }
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

/// the subtle hover-revealed control row over the prompter text: snap-to-notch and close.
private struct PrompterControlsView: View {
    let onClose: () -> Void
    let onSnap: () -> Void

    var body: some View {
        HStack {
            Button("Snap to Notch", systemImage: "arrow.up.to.line", action: onSnap)
            Button("Close", systemImage: "xmark", action: onClose)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.85))
        .padding(8)
    }
}
