//
//  EmptyEditorView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// placeholder shown in the detail pane when no script is selected.
struct EmptyEditorView: View {
    var body: some View {
        ContentUnavailableView(
            "No Script Selected",
            systemImage: "doc.text",
            description: Text("Select a script from the library or create a new one.")
        )
    }
}

#Preview {
    EmptyEditorView()
}
