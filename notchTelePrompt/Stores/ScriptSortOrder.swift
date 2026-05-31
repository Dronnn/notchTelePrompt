//
//  ScriptSortOrder.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
import SwiftData

/// sort options for listing scripts.
enum ScriptSortOrder: CaseIterable {
    case createdDescending
    case createdAscending
    case updatedDescending
    case updatedAscending
    case titleAscending

    /// human-readable label for sort pickers.
    var title: String {
        switch self {
        case .createdDescending: "Newest"
        case .createdAscending: "Oldest"
        case .updatedDescending: "Recently Edited"
        case .updatedAscending: "Least Recently Edited"
        case .titleAscending: "Title"
        }
    }

    /// the SwiftData sort descriptors that realize this ordering.
    var sortDescriptors: [SortDescriptor<Script>] {
        switch self {
        case .createdDescending: [SortDescriptor(\.createdAt, order: .reverse)]
        case .createdAscending: [SortDescriptor(\.createdAt, order: .forward)]
        case .updatedDescending: [SortDescriptor(\.updatedAt, order: .reverse)]
        case .updatedAscending: [SortDescriptor(\.updatedAt, order: .forward)]
        case .titleAscending: [SortDescriptor(\.title, comparator: .localizedStandard, order: .forward)]
        }
    }
}
