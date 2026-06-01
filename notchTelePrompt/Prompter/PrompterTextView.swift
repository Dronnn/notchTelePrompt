//
//  PrompterTextView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// scrollable rendering of the script's lines, keeping the current reading line centered.
/// uses a LazyVStack so only visible lines render for long scripts (performance §6.4).
struct PrompterTextView: View {
    let viewModel: PrompterViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PrompterStyle.lineSpacing) {
                    // iterate by index: EnumeratedSequence isn't a RandomAccessCollection before macOS 26.
                    ForEach(viewModel.lines.indices, id: \.self) { index in
                        PrompterLineView(
                            text: viewModel.lines[index],
                            distance: index - viewModel.currentLineIndex
                        )
                        .id(index)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.currentLineIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
            .onChange(of: viewModel.currentScript?.id) { _, _ in
                // re-anchor when the script switches even if the line index is unchanged.
                proxy.scrollTo(viewModel.currentLineIndex, anchor: .center)
            }
        }
    }
}
