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

    @Test
    func panelStyleMaskContainsResizable() {
        #expect(makePanel().styleMask.contains(.resizable))
    }

    @Test
    func panelStyleMaskOmitsTitleBarChrome() {
        // .borderless is raw value 0, so assert the chrome masks are absent to catch accidental chrome.
        let mask = makePanel().styleMask
        #expect(mask.contains(.titled) == false)
        #expect(mask.contains(.closable) == false)
        #expect(mask.contains(.miniaturizable) == false)
    }

    // MARK: - Minimum Size

    @Test
    func panelHasMinimumSize() {
        #expect(makePanel().minSize == PrompterPanelConfiguration.minSize)
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
