//
//  ScriptEditorView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// detail pane for editing a script's title and body, with live stats and an autosaving view model.
struct ScriptEditorView: View {
    @Bindable var viewModel: ScriptEditorViewModel
    let importExportViewModel: ImportExportViewModel
    let onStartPrompter: ((Script) -> Void)?

    var body: some View {
        if viewModel.selectedScript == nil {
            EmptyEditorView()
        } else {
            ScriptEditorContentView(
                viewModel: viewModel,
                importExportViewModel: importExportViewModel,
                onStartPrompter: onStartPrompter
            )
        }
    }
}
