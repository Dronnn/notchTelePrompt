//
//  Color+Hex.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// hex serialisation for the prompter's stored text colour. ScriptPrompterSettings persists the colour
/// as a "#RRGGBB" string, so the picker and the renderer bridge through these two helpers.
extension Color {
    /// parses a "#RRGGBB" (or "RRGGBB") string into a colour, returning nil for anything malformed.
    init?(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return nil
        }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    /// the colour as "#RRGGBB". NSColor is used solely to serialise the picker's colour into sRGB
    /// components for storage; the conversion is guarded and falls back to white when it fails.
    var hexString: String {
        guard let srgb = NSColor(self).usingColorSpace(.sRGB) else {
            return "#FFFFFF"
        }
        let red = Self.byte(srgb.redComponent)
        let green = Self.byte(srgb.greenComponent)
        let blue = Self.byte(srgb.blueComponent)
        return "#\(Self.twoDigitHex(red))\(Self.twoDigitHex(green))\(Self.twoDigitHex(blue))"
    }

    /// maps a 0...1 colour component to a clamped 0...255 byte.
    private static func byte(_ component: CGFloat) -> Int {
        Int((component * 255).rounded().clamped(to: 0 ... 255))
    }

    /// a zero-padded, upper-case two-digit hex string for a single byte.
    private static func twoDigitHex(_ value: Int) -> String {
        let digits = String(value, radix: 16, uppercase: true)
        return digits.count == 1 ? "0\(digits)" : digits
    }
}

private extension CGFloat {
    /// clamps the value to the given closed range.
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
