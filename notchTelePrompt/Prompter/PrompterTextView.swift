//
//  PrompterTextView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// offset-driven rendering of the script's lines. instead of a scroll view, the line stack is shifted
/// by `-engine.offset` inside a clipped container, with half-viewport top/bottom padding so the first
/// and last lines can sit centered (breathing room, folds in deferred 6.6). the visible viewport
/// height is measured with a background reader and fed to the engine; the content height is computed
/// from metrics, not measured. emphasis uses the offset-derived current line index.
struct PrompterTextView: View {
    let viewModel: PrompterViewModel

    @State private var viewportHeight: Double = 0

    var body: some View {
        let engine = viewModel.scrollEngine
        PrompterLineStackView(
            viewModel: viewModel,
            verticalPadding: viewportHeight / 2
        )
        .offset(y: -engine.offset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .background {
            // measure the viewport once layout settles and feed it to the engine via the view model.
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.height, initial: true) { _, newHeight in
                        viewportHeight = newHeight
                        viewModel.setViewportHeight(newHeight)
                    }
            }
        }
        .overlay {
            // wheel / trackpad scrolling routed into the engine as manual nudges.
            ScrollWheelCatcher { delta in
                engine.nudge(by: delta)
            }
        }
        .onChange(of: viewModel.lines.count, initial: true) { _, _ in
            // live edits change the content height; recompute it outside the body's read path.
            viewModel.syncEngineGeometry()
        }
    }
}

/// the padded, top-aligned line stack rendered by the offset-driven prompter. kept as its own view
/// so the offset/clip/measurement concerns stay in PrompterTextView.
private struct PrompterLineStackView: View {
    let viewModel: PrompterViewModel
    let verticalPadding: Double

    var body: some View {
        // a LazyVStack keeps only visible lines realized for long scripts (performance §38).
        LazyVStack(alignment: .leading, spacing: PrompterStyle.lineSpacing) {
            // iterate by index: EnumeratedSequence isn't a RandomAccessCollection before macOS 26.
            ForEach(viewModel.lines.indices, id: \.self) { index in
                PrompterLineView(
                    text: viewModel.lines[index],
                    distance: index - viewModel.currentLineIndex,
                    fontSize: CGFloat(viewModel.fontSize)
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
