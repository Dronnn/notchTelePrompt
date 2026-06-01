//
//  PrompterContentView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// prompter rendering: the current script text on a translucent dark background. the non-interactive chrome
/// (countdown, progress bar, voice indicator) and the top-right control row are not here — they live in
/// separate hosting views above this one (see PrompterChromeView and PrompterControlsView), because the
/// scroll-catcher's native subview inside the text view composites above any sibling overlay in this host.
struct PrompterContentView: View {
    let viewModel: PrompterViewModel

    var body: some View {
        PrompterBodyView(viewModel: viewModel)
            .background(.black.opacity(viewModel.backgroundOpacity))
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
        } else if viewModel.currentScript?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            Text("This script is empty.")
                .foregroundStyle(viewModel.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            PrompterTextView(viewModel: viewModel)
        }
    }
}
