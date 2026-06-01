//
//  VoiceAuthorizationStatus.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AVFoundation

/// microphone permission state surfaced by the voice engine (spec §9.1).
nonisolated enum VoiceAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    /// no usable input device / invalid capture format.
    case unavailable

    /// the live microphone permission state, read straight from the system. used by the voice pane to
    /// reflect access without starting capture; .unavailable is only reachable once the engine runs.
    static var current: VoiceAuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }
}
