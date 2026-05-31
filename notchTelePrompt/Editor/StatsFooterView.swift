//
//  StatsFooterView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// compact footer summarizing the current script's word/character counts and reading time.
struct StatsFooterView: View {
    let wordCount: Int
    let charCount: Int
    let readingTime: String

    var body: some View {
        HStack {
            Label("\(wordCount) words", systemImage: "text.word.spacing")
            Label("\(charCount) characters", systemImage: "character")
            Label(readingTime, systemImage: "clock")
            Spacer()
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .labelStyle(.titleAndIcon)
    }
}

#Preview {
    StatsFooterView(wordCount: 120, charCount: 640, readingTime: "< 1 min")
        .padding()
}
