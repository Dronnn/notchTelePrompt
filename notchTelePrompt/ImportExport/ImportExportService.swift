//
//  ImportExportService.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
import UniformTypeIdentifiers

/// thin main-actor wrapper around AppKit panels and the pasteboard.
/// delegates all text processing to ScriptTextCore and runs file I/O off the main thread.
/// returns decoded (title, text) so the coordinator owns store mutations.
@MainActor
final class ImportExportService {
    private let allowedTypes: [UTType] = [.plainText, ExportFormat.md.utType]

    // MARK: - Import

    /// presents an open panel for .txt/.md and returns the decoded title and text.
    /// returns nil when the user cancels; throws on read/decode failure.
    func importFromPanel() async throws -> (title: String, text: String)? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        NSApp.activate()
        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }
        return try await decodeFile(at: url, securityScoped: false)
    }

    // MARK: - Export

    /// presents a save panel and writes the script text in the chosen format.
    /// returns false when the user cancels; throws on write failure.
    @discardableResult
    func exportToPanel(title: String, text: String, suggestedFormat: ExportFormat) async throws -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [suggestedFormat.utType]
        panel.nameFieldStringValue = suggestedName(title: title, format: suggestedFormat)

        NSApp.activate()
        guard panel.runModal() == .OK, let url = panel.url else {
            return false
        }

        let data = ScriptTextCore.fileData(for: text, format: suggestedFormat)
        do {
            try await Task.detached { try data.write(to: url, options: .atomic) }.value
        } catch {
            throw ImportExportError.exportFailed(underlying: error)
        }
        return true
    }

    // MARK: - Clipboard

    /// builds a title and text from the current pasteboard string.
    func pasteFromClipboard() throws -> (title: String, text: String) {
        guard let raw = NSPasteboard.general.string(forType: .string), !raw.isEmpty else {
            throw ImportExportError.noTextInClipboard
        }
        let text = ScriptTextCore.normalizeLineBreaks(raw)
        return (ScriptTextCore.title(forFirstLineOf: text), text)
    }

    // MARK: - Drag-drop

    /// reads a dropped file URL using security-scoped access (drag URLs are not auto-scoped for sandboxed apps).
    func readFileText(at url: URL) async throws -> (title: String, text: String) {
        try await decodeFile(at: url, securityScoped: true)
    }

    // MARK: - Helpers

    private func decodeFile(at url: URL, securityScoped: Bool) async throws -> (title: String, text: String) {
        let data: Data
        do {
            data = try await Task.detached {
                let didStart = securityScoped ? url.startAccessingSecurityScopedResource() : false
                defer { if didStart { url.stopAccessingSecurityScopedResource() } }
                return try Data(contentsOf: url)
            }.value
        } catch {
            throw ImportExportError.unreadableFile(underlying: error)
        }

        guard let decoded = ScriptTextCore.decodeText(from: data) else {
            throw ImportExportError.unencodableText
        }
        let text = ScriptTextCore.normalizeLineBreaks(decoded)
        return (ScriptTextCore.title(forFirstLineOf: text), text)
    }

    private func suggestedName(title: String, format: ExportFormat) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? String(localized: "Untitled") : trimmed
        return "\(base).\(format.fileExtension)"
    }
}
