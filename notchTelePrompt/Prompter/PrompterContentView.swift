//
//  PrompterContentView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// minimal prompter rendering: the current script text on a translucent dark background.
/// phase 6 replaces this body with rich, scrollable, mirrored rendering.
struct PrompterContentView: View {
    let viewModel: PrompterViewModel

    var body: some View {
        ScrollView {
            Text(viewModel.currentScript?.text ?? String(localized: "No script selected."))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .scrollIndicators(.hidden)
        .background(.black.opacity(0.82))
        .clipShape(.rect(cornerRadius: 8))
    }
}
