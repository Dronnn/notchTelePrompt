//
//  FontSizeControlView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// compact prompter font-size stepper for the editor footer: smaller, current value, larger.
/// reads and writes the single global font size through the editor view model so changes sync live
/// with the preferences pane and the overlay.
struct FontSizeControlView: View {
    let viewModel: ScriptEditorViewModel

    var body: some View {
        HStack {
            Button("Smaller text", systemImage: "textformat.size.smaller") {
                viewModel.decreaseFontSize()
            }
            .disabled(!viewModel.canDecreaseFontSize)
            .keyboardShortcut("-", modifiers: .command)

            Text(viewModel.fontSize, format: .number.precision(.fractionLength(0)))
                .monospacedDigit()
                .accessibilityLabel("Font size")
                .accessibilityValue(Text(viewModel.fontSize, format: .number.precision(.fractionLength(0))))

            Button("Larger text", systemImage: "textformat.size.larger") {
                viewModel.increaseFontSize()
            }
            .disabled(!viewModel.canIncreaseFontSize)
            .keyboardShortcut("=", modifiers: .command)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }
}
