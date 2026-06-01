//
//  PrompterLineView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a single prompter line rendered uniformly. the reading emphasis is applied by the stack's
/// center-fixed highlight band, not per line, so this view stays simple and free of the view model.
/// colour and alignment are passed in from the stack.
struct PrompterLineView: View {
    let text: String
    let fontSize: CGFloat
    let textColor: Color
    let textAlignment: TextAlignment

    var body: some View {
        // a blank line renders a space so it keeps paragraph height.
        Text(text.isEmpty ? " " : text)
            .font(.system(size: fontSize))
            .foregroundStyle(textColor)
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
