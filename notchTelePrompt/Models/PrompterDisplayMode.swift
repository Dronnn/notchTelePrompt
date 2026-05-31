//
//  PrompterDisplayMode.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// how the prompter overlay is positioned on screen.
enum PrompterDisplayMode: String, Codable, CaseIterable {
    case notch
    case topOverlay
    case floating
}
