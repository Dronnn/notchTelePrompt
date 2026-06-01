//
//  ScriptPrompterSettingsTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct ScriptPrompterSettingsTests {
    // MARK: - Round-trip

    @Test
    func encodeDecodeRoundTripsIncludingFontSize() throws {
        let original = ScriptPrompterSettings(
            fontSize: 42,
            lineSpacing: 12,
            textColorHex: "#FF0000",
            backgroundOpacity: 0.5,
            scrollSpeed: 200,
            displayMode: .floating,
            alignment: .left
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScriptPrompterSettings.self, from: data)
        #expect(decoded == original)
        #expect(decoded.fontSize == 42)
    }

    // MARK: - Back-compat

    @Test
    func decodingBlobWithoutFontSizeYieldsDefault() throws {
        // a blob persisted before fontSize existed: the key is simply absent.
        let legacyJSON = """
        {
            "lineSpacing": 8,
            "textColorHex": "#FFFFFF",
            "backgroundOpacity": 0.85,
            "scrollSpeed": 150,
            "displayMode": "notch",
            "alignment": "center"
        }
        """
        let data = Data(legacyJSON.utf8)
        let decoded = try JSONDecoder().decode(ScriptPrompterSettings.self, from: data)
        #expect(decoded.fontSize == PrompterFontSize.default)
    }
}
