//
//  PrompterTextView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// offset-driven rendering of the script's lines. the line stack scrolls behind a reading highlight that
/// is pinned to the centre of the PROMPTER WINDOW: everything outside a one-line-tall band is dimmed by a
/// veil, so the bright reading line is always exactly at the window centre and can never drift above or
/// below or run off as the text scrolls. the band lives in an overlay over the window-filling frame, so it
/// re-centres automatically when the window is resized — no screen geometry is involved.
///
/// sizes are measured with `.background` GeometryReaders (which report the actual allocated size), NOT a
/// top-level GeometryReader: hosted in an NSHostingView, a top-level reader is proposed the screen size,
/// which is why the band previously landed at the monitor centre instead of the window centre.
///
/// the stack's real rendered height is measured (so the true font line height and any wrapping are
/// accounted for) and fed to the engine, so the first line starts centred (empty top half = overscroll),
/// the last line ends centred (empty bottom half), independent of wrapping.
struct PrompterTextView: View {
    let viewModel: PrompterViewModel

    /// the prompter window's measured height; drives the centring offset. read from a background reader
    /// (the real allocated size), so it is the window's height, never the screen's.
    @State private var viewportHeight: Double = 0

    /// opacity of the dimming veil over the lines outside the centred reading band.
    private static let dimVeilOpacity = 0.6

    var body: some View {
        let engine = viewModel.scrollEngine
        PrompterLineStackView(viewModel: viewModel)
            .background {
                // measure the stack's real rendered height (true font line height + wrapping) and feed it
                // to the engine so the scroll extent and overscroll are correct.
                GeometryReader { stackProxy in
                    Color.clear
                        .onChange(of: stackProxy.size.height, initial: true) { _, height in
                            viewModel.setMeasuredContentHeight(height)
                        }
                }
            }
            .offset(y: viewportHeight / 2 - viewModel.fontSize / 2 - engine.offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay {
                PrompterReadingVeil(
                    bandHeight: viewModel.fontSize + viewModel.lineSpacing,
                    dimOpacity: Self.dimVeilOpacity
                )
            }
            .clipped()
            .overlay {
                // wheel / trackpad scrolling routed into the engine as manual nudges.
                ScrollWheelCatcher { delta in
                    engine.nudge(by: delta)
                }
            }
            .background {
                // measure the prompter window's height (the actual allocated size, not the screen);
                // feeds the centring offset and the engine. updates as the window is resized.
                GeometryReader { viewportProxy in
                    Color.clear
                        .onChange(of: viewportProxy.size.height, initial: true) { _, height in
                            viewportHeight = height
                            viewModel.setViewportHeight(height)
                        }
                }
            }
            .onChange(of: viewModel.lines.count, initial: true) { _, _ in
                // keep the engine's font / line spacing in step; the content height is measured above.
                viewModel.syncEngineGeometry()
            }
    }
}

/// the dimming veil with a clear, one-line-tall reading band fixed to the centre of the window. the two
/// veil halves flex equally, so the clear band is always exactly centred in whatever size it is given.
private struct PrompterReadingVeil: View {
    let bandHeight: Double
    let dimOpacity: Double

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(.black.opacity(dimOpacity))
            Color.clear.frame(height: bandHeight)
            Rectangle().fill(.black.opacity(dimOpacity))
        }
        .allowsHitTesting(false)
    }
}

/// the top-aligned line stack. a plain VStack (not lazy) so its measured height is the true total even for
/// off-screen lines, which the centring math depends on. no vertical padding: the overscroll breathing
/// room comes from the offset translation.
private struct PrompterLineStackView: View {
    let viewModel: PrompterViewModel

    var body: some View {
        VStack(alignment: viewModel.stackAlignment, spacing: viewModel.lineSpacing) {
            // iterate by index: EnumeratedSequence isn't a RandomAccessCollection before macOS 26.
            ForEach(viewModel.lines.indices, id: \.self) { index in
                PrompterLineView(
                    text: viewModel.lines[index],
                    fontSize: CGFloat(viewModel.fontSize),
                    textColor: viewModel.textColor,
                    textAlignment: viewModel.textAlignment
                )
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: stackFrameAlignment)
    }

    /// keeps the stack pinned to the same edge as the lines.
    private var stackFrameAlignment: Alignment {
        switch viewModel.stackAlignment {
        case .center: .center
        case .trailing: .trailing
        default: .leading
        }
    }
}
