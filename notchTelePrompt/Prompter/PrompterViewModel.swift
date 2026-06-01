//
//  PrompterViewModel.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// holds the state the prompter overlay renders.
/// phase 6 expands this with scroll offset, playback state, and speed.
@MainActor
@Observable
final class PrompterViewModel {
    var currentScript: Script?
}
