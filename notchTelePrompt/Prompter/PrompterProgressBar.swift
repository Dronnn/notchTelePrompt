//
//  PrompterProgressBar.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a thin, subtle progress indicator pinned to the bottom edge of the prompter (§28).
/// a low-opacity track with a fill whose width is a fraction of the container width.
struct PrompterProgressBar: View {
    let progress: Double

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.12))
            Capsule()
                .fill(.white.opacity(0.4))
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * min(max(progress, 0), 1)
                }
        }
        .frame(height: PrompterStyle.progressBarHeight)
    }
}
