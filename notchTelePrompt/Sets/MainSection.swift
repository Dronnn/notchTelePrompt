//
//  MainSection.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// the two top-level areas of the main window: the script library/editor, or the prompt sets editor.
/// the sidebar switches between them with a segmented control.
enum MainSection: String, CaseIterable, Identifiable {
    case library
    case sets

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .library: "Library"
        case .sets: "Sets"
        }
    }

    var systemImage: String {
        switch self {
        case .library: "doc.text"
        case .sets: "rectangle.stack"
        }
    }
}
