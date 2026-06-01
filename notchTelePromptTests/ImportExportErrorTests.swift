//
//  ImportExportErrorTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import Testing

struct ImportExportErrorTests {
    private struct SampleError: LocalizedError {
        var errorDescription: String? { "disk is full" }
    }

    @Test
    func noTextInClipboardHasDescription() {
        let description = ImportExportError.noTextInClipboard.errorDescription
        #expect(description?.isEmpty == false)
    }

    @Test
    func unreadableFileHasDescription() {
        let description = ImportExportError.unreadableFile(underlying: SampleError()).errorDescription
        #expect(description?.isEmpty == false)
    }

    @Test
    func unencodableTextHasDescription() {
        let description = ImportExportError.unencodableText.errorDescription
        #expect(description?.isEmpty == false)
    }
}
