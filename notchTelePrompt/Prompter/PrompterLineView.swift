//
//  PrompterLineView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a single prompter line, dimmed by its distance from the current reading line
/// and emphasized (bold) when it is the current line. colour and alignment are passed in from the stack
/// so this view stays free of the view model.
struct PrompterLineView: View {
    let text: String
    let distance: Int
    let fontSize: CGFloat
    let textColor: Color
    let textAlignment: TextAlignment

    var body: some View {
        // a blank line renders a space so it keeps paragraph height.
        Text(text.isEmpty ? " " : text)
            .font(.system(size: fontSize))
            .bold(PrompterLineEmphasis.isCurrent(distance))
            .foregroundStyle(textColor)
            .opacity(PrompterLineEmphasis.opacity(distanceFromCurrent: distance))
            .multilineTextAlignment(textAlignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    /// maps the text alignment to the frame alignment so a single line also sits at the chosen edge.
    private var frameAlignment: Alignment {
        switch textAlignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}
