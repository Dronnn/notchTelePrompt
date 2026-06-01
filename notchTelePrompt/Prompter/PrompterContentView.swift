//
//  PrompterContentView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// minimal prompter rendering: the current script text on a translucent dark background,
/// with subtle close and snap-to-notch controls that fade in on hover.
/// phase 6 replaces the text body with rich, scrollable, mirrored rendering.
struct PrompterContentView: View {
    let viewModel: PrompterViewModel
    let onClose: () -> Void
    let onSnap: () -> Void

    @State private var isHovering = false

    var body: some View {
        ScrollView {
            Text(viewModel.currentScript?.text ?? String(localized: "No script selected."))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .scrollIndicators(.hidden)
        .background(.black.opacity(0.82))
        .overlay(alignment: .topTrailing) {
            PrompterControlsView(onClose: onClose, onSnap: onSnap)
                .opacity(isHovering ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .clipShape(.rect(cornerRadius: 8))
        .onHover { isHovering = $0 }
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
