//
//  PrompterLineView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a single prompter line, dimmed by its distance from the current reading line
/// and emphasized (bold) when it is the current line.
struct PrompterLineView: View {
    let text: String
    let distance: Int
    let fontSize: CGFloat

    var body: some View {
        // a blank line renders a space so it keeps paragraph height.
        Text(text.isEmpty ? " " : text)
            .font(.system(size: fontSize))
            .bold(PrompterLineEmphasis.isCurrent(distance))
            .foregroundStyle(.white)
            .opacity(PrompterLineEmphasis.opacity(distanceFromCurrent: distance))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
