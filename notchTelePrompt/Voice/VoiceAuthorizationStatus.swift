//
//  VoiceAuthorizationStatus.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

/// microphone permission state surfaced by the voice engine (spec §9.1).
nonisolated enum VoiceAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    /// no usable input device / invalid capture format.
    case unavailable
}
