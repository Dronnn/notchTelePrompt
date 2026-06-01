//
//  PrompterCountdownOverlay.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// a large, clear countdown number shown over the prompter before scrolling starts (spec §17).
/// the caller shows it only while the engine is in the countdown state.
struct PrompterCountdownOverlay: View {
    let secondsRemaining: Int

    var body: some View {
        Text(secondsRemaining, format: .number)
            .font(.system(size: 64, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black.opacity(0.3))
    }
}
