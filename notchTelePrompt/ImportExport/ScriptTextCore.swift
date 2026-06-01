//
//  ScriptTextCore.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation

/// pure, stateless text-handling logic for import/export/clipboard.
/// no AppKit, no SwiftData; fully testable without a running app.
/// the single home of encoding, line-break policy and title-derivation rules.
nonisolated enum ScriptTextCore {
    static let maxTitleLength = 60

    // MARK: - Decoding

    /// returns nil only when the data cannot be decoded as UTF-8 at all.
    static func decodeText(from data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }

    // MARK: - Line-break policy

    /// normalize to \n on import, store \n, export \n. \r\n and lone \r become \n; \n is left untouched.
    /// the spec (§35, §44.9) requires preserving paragraph structure, not the byte-level line terminator;
    /// macOS text APIs treat \n as canonical, and normalizing avoids invisible whitespace diffs in SwiftData.
    static func normalizeLineBreaks(_ text: String) -> String {
        text
            .replacing("\r\n", with: "\n")
            .replacing("\r", with: "\n")
    }

    // MARK: - Title

    /// takes the first non-empty line, trimmed; truncates at maxTitleLength with an ellipsis;
    /// falls back to a date-based title when the text is empty or every line is blank.
    static func title(forFirstLineOf text: String, fallbackDate: Date = .now) -> String {
        let firstNonEmpty = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .lazy
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        guard let firstNonEmpty else {
            let date = fallbackDate.formatted(.dateTime.day().month(.abbreviated).year())
            return String(localized: "Script – \(date)")
        }

        guard firstNonEmpty.count > maxTitleLength else {
            return firstNonEmpty
        }
        return firstNonEmpty.prefix(maxTitleLength) + "…"
    }

    // MARK: - Encoding

    /// encodes text as UTF-8; format only affects the suggested extension, not the bytes.
    /// the ?? Data() exists only to avoid a force-unwrap; UTF-8 encoding cannot fail for a valid String.
    static func fileData(for text: String, format _: ExportFormat) -> Data {
        text.data(using: .utf8) ?? Data()
    }
}
