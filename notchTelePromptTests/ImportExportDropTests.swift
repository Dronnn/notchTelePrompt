//
//  ImportExportDropTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import Foundation
@testable import notchTelePrompt
import SwiftData
import Testing

@MainActor
struct ImportExportDropTests {
    private func makeStore() throws -> ScriptStore {
        let container = try ModelContainerFactory.makeInMemory()
        return ScriptStore(container: container)
    }

    @Test
    func droppingFileIntoEmptyEditorCreatesAndSelectsScript() async throws {
        let store = try makeStore()
        let library = LibraryViewModel(store: store)
        let importExport = ImportExportViewModel(store: store, libraryViewModel: library)
        let editor = ScriptEditorViewModel(store: store)
        let url = try makeTemporaryFile(contents: "Hello from Finder")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await importExport.handleDroppedFile(url: url, into: editor)

        #expect(importExport.pendingDrop == nil)
        #expect(library.scripts.count == 1)
        #expect(library.scripts.first?.title == "Hello from Finder")
        #expect(library.selectedScript?.text == "Hello from Finder")
    }

    @Test
    func droppingFileAsNewScriptOpensItForEditing() async throws {
        let store = try makeStore()
        let library = LibraryViewModel(store: store)
        let importExport = ImportExportViewModel(store: store, libraryViewModel: library)
        let url = try makeTemporaryFile(contents: "Markdown prompt")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await importExport.handleDroppedFileAsNewScript(url: url)

        #expect(library.scripts.count == 1)
        #expect(library.selectedScript?.title == "Markdown prompt")
        #expect(library.selectedScript?.text == "Markdown prompt")
    }

    @Test
    func droppingFileOntoEditedScriptAsksBeforeReplacing() async throws {
        let store = try makeStore()
        let script = try store.create(title: "Current", text: "Existing text")
        let library = LibraryViewModel(store: store)
        let importExport = ImportExportViewModel(store: store, libraryViewModel: library)
        let editor = ScriptEditorViewModel(store: store)
        editor.selectedScript = script
        let url = try makeTemporaryFile(contents: "Dropped text")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        await importExport.handleDroppedFile(url: url, into: editor)

        let pending = try #require(importExport.pendingDrop)
        #expect(pending.title == "Dropped text")
        #expect(pending.text == "Dropped text")
        #expect(library.scripts.count == 1)
    }

    private func makeTemporaryFile(contents: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "Dropped.txt")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
