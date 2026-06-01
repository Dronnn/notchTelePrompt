//
//  PrompterSettingsView.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import SwiftUI

/// the prompter pane of preferences: the global appearance and reading defaults that drive the overlay.
/// every control binds straight to the store, which persists on didSet and notifies a live overlay.
/// font size is the only per-script setting; here it sets the default a new script inherits.
struct PrompterSettingsView: View {
    @Bindable var preferencesStore: PreferencesStore

    var body: some View {
        Form {
            PrompterTextSettingsSection(preferencesStore: preferencesStore)
            PrompterBackgroundSettingsSection(preferencesStore: preferencesStore)
            PrompterReadingSettingsSection(preferencesStore: preferencesStore)
            PrompterPresetsSection(preferencesStore: preferencesStore)
        }
        .formStyle(.grouped)
    }
}

// MARK: - Text

/// font size, text colour and alignment for the prompter text.
private struct PrompterTextSettingsSection: View {
    @Bindable var preferencesStore: PreferencesStore

    /// bridges the stored "#RRGGBB" colour to the SwiftUI ColorPicker.
    private var textColor: Binding<Color> {
        Binding(
            get: { Color(hex: preferencesStore.prompterDefaults.textColorHex) ?? .white },
            set: { preferencesStore.prompterDefaults.textColorHex = $0.hexString }
        )
    }

    var body: some View {
        Section("Text") {
            Slider(
                value: $preferencesStore.prompterDefaults.fontSize,
                in: PrompterFontSize.min ... PrompterFontSize.max,
                step: PrompterFontSize.step
            ) {
                Text("Font Size")
            }
            // the slider's label closure already exposes "Font Size"; expose the size in points.
            .accessibilityValue(
                Text(preferencesStore.prompterDefaults.fontSize, format: .number.precision(.fractionLength(0)))
                    + Text(" pt")
            )
            LabeledContent("Font Size") {
                Text(preferencesStore.prompterDefaults.fontSize, format: .number.precision(.fractionLength(0)))
                    + Text(" pt")
            }

            ColorPicker("Text Color", selection: textColor, supportsOpacity: false)

            Picker("Alignment", selection: $preferencesStore.prompterDefaults.alignment) {
                ForEach(PrompterAlignment.allCases) { alignment in
                    Text(alignment.title).tag(alignment)
                }
            }
        }
    }
}

// MARK: - Background

/// the prompter overlay's background opacity.
private struct PrompterBackgroundSettingsSection: View {
    @Bindable var preferencesStore: PreferencesStore

    var body: some View {
        Section("Background") {
            Slider(value: $preferencesStore.prompterDefaults.backgroundOpacity, in: 0 ... 1) {
                Text("Opacity")
            }
            // the slider's label closure already exposes "Opacity"; expose the level as a percent value.
            .accessibilityValue(
                Text(
                    preferencesStore.prompterDefaults.backgroundOpacity,
                    format: .percent.precision(.fractionLength(0))
                )
            )
            LabeledContent("Opacity") {
                Text(
                    preferencesStore.prompterDefaults.backgroundOpacity,
                    format: .percent.precision(.fractionLength(0))
                )
            }
        }
    }
}

// MARK: - Reading

/// line spacing, scroll speed and the pre-start countdown.
private struct PrompterReadingSettingsSection: View {
    @Bindable var preferencesStore: PreferencesStore

    var body: some View {
        Section("Reading") {
            Slider(value: $preferencesStore.prompterDefaults.lineSpacing, in: 0 ... 24, step: 1) {
                Text("Line Spacing")
            }
            // the slider's label closure already exposes "Line Spacing"; expose the spacing in points.
            .accessibilityValue(
                Text(preferencesStore.prompterDefaults.lineSpacing, format: .number.precision(.fractionLength(0)))
                    + Text(" pt")
            )
            LabeledContent("Line Spacing") {
                Text(preferencesStore.prompterDefaults.lineSpacing, format: .number.precision(.fractionLength(0)))
                    + Text(" pt")
            }

            Slider(
                value: $preferencesStore.prompterDefaults.scrollSpeed,
                in: ScrollSpeed.minWordsPerMinute ... ScrollSpeed.maxWordsPerMinute
            ) {
                Text("Scroll Speed")
            }
            // the slider's label closure already exposes "Scroll Speed"; expose the speed in WPM.
            .accessibilityValue(
                Text(preferencesStore.prompterDefaults.scrollSpeed, format: .number.precision(.fractionLength(0)))
                    + Text(" WPM")
            )
            LabeledContent("Scroll Speed") {
                Text(preferencesStore.prompterDefaults.scrollSpeed, format: .number.precision(.fractionLength(0)))
                    + Text(" WPM")
            }

            Picker("Countdown", selection: $preferencesStore.countdown) {
                ForEach(CountdownOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        }
    }
}

// MARK: - Presets

/// one-tap appearance bundles that overwrite the current prompter defaults.
private struct PrompterPresetsSection: View {
    @Bindable var preferencesStore: PreferencesStore

    var body: some View {
        Section("Presets") {
            ForEach(PrompterPreset.allCases) { preset in
                Button(preset.title) {
                    preferencesStore.prompterDefaults = preset.settings
                }
            }
        }
    }
}
