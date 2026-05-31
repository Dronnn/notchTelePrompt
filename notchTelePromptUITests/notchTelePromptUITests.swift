//
//  notchTelePromptUITests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import XCTest

final class NotchPrompterUITests: XCTestCase {
    override func setUpWithError() throws {
        // stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() {
        // the app is a menu bar utility (LSUIElement); launching should not crash.
        let app = XCUIApplication()
        app.launch()
    }
}
