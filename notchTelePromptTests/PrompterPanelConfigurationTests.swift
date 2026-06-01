//
//  PrompterPanelConfigurationTests.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import AppKit
@testable import notchTelePrompt
import Testing

@MainActor
struct PrompterPanelConfigurationTests {
    /// builds a configured panel through the production path used by the window controller.
    private func makePanel() -> PrompterPanel {
        PrompterPanel(contentView: NSView())
    }

    // MARK: - Style Mask

    @Test
    func panelStyleMaskContainsBorderless() {
        #expect(makePanel().styleMask.contains(.borderless))
    }

    @Test
    func panelStyleMaskContainsNonactivating() {
        #expect(makePanel().styleMask.contains(.nonactivatingPanel))
    }

    // MARK: - Level

    @Test
    func panelLevelIsStatusBar() {
        #expect(makePanel().level == .statusBar)
    }

    // MARK: - Transparency

    @Test
    func panelIsNotOpaque() {
        #expect(makePanel().isOpaque == false)
    }

    @Test
    func panelHasNoShadow() {
        #expect(makePanel().hasShadow == false)
    }

    // MARK: - Capture Exclusion

    @Test
    func panelSharingTypeIsNone() {
        #expect(makePanel().sharingType == .none)
    }

    // MARK: - Collection Behavior

    @Test
    func panelCollectionBehaviorOmitsCanJoinAllSpaces() {
        #expect(makePanel().collectionBehavior.contains(.canJoinAllSpaces) == false)
    }

    @Test
    func panelCollectionBehaviorContainsFullScreenAuxiliary() {
        #expect(makePanel().collectionBehavior.contains(.fullScreenAuxiliary))
    }

    @Test
    func panelCollectionBehaviorContainsStationary() {
        #expect(makePanel().collectionBehavior.contains(.stationary))
    }

    // MARK: - Focus

    @Test
    func panelCannotBecomeKey() {
        #expect(makePanel().canBecomeKey == false)
    }

    @Test
    func panelCannotBecomeMain() {
        #expect(makePanel().canBecomeMain == false)
    }
}
