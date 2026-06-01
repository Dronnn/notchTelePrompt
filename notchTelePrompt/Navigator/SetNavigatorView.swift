//
//  SetNavigatorView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the floating set navigator's content: a translucent dark panel listing the active set's prompts.
/// a header shows the set name with prev/next stepping; each row is a numbered script the user can tap
/// to send to the prompter, or drag to reorder. matches the prompter's dark translucent look.
struct SetNavigatorView: View {
    let viewModel: SetNavigatorViewModel

    var body: some View {
        Group {
            if viewModel.activeSet == nil {
                SetNavigatorEmptyView(message: Text("No active set"))
            } else if viewModel.scripts.isEmpty {
                SetNavigatorEmptyView(message: Text("This set is empty"))
            } else {
                SetNavigatorListView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.82))
        .foregroundStyle(.white)
        .clipShape(.rect(cornerRadius: 8))
    }
}

/// the populated navigator: header with the set name and prev/next controls, then the script list.
private struct SetNavigatorListView: View {
    let viewModel: SetNavigatorViewModel

    var body: some View {
        VStack(spacing: 0) {
            SetNavigatorHeaderView(viewModel: viewModel)
            List {
                // iterate over indices (a RandomAccessCollection of Int) so .onMove is available and the
                // 1-based row number is derived directly; the script id keeps row identity stable.
                ForEach(viewModel.scripts.indices, id: \.self) { index in
                    let script = viewModel.scripts[index]
                    SetNavigatorRowView(
                        number: index + 1,
                        title: script.title,
                        isSelected: script.id == viewModel.selectedScriptID
                    ) {
                        viewModel.select(script)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove { offsets, destination in
                    viewModel.move(fromOffsets: offsets, toOffset: destination)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
        }
    }
}

/// the navigator header: the active set's name with prev/next stepping that drives the selection.
private struct SetNavigatorHeaderView: View {
    let viewModel: SetNavigatorViewModel

    var body: some View {
        HStack {
            Text(viewModel.activeSet?.name ?? "")
                .bold()
                .lineLimit(1)
            Spacer()
            Button("Previous prompt", systemImage: "chevron.up") {
                viewModel.previous()
            }
            .disabled(!viewModel.canGoPrevious)
            Button("Next prompt", systemImage: "chevron.down") {
                viewModel.next()
            }
            .disabled(!viewModel.canGoNext)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .padding(8)
    }
}

/// centered placeholder shown when there is no active set or the active set has no scripts.
private struct SetNavigatorEmptyView: View {
    let message: Text

    var body: some View {
        message
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
