//
//  PrompterAlignment.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// horizontal alignment of the prompter text.
nonisolated enum PrompterAlignment: String, Codable, CaseIterable, Identifiable {
    case left
    case center
    case right

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .left: "Left"
        case .center: "Center"
        case .right: "Right"
        }
    }
}
