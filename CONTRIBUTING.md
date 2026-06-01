# Contributing to NotchPrompter

Thanks for your interest in improving NotchPrompter. Bug reports, ideas, and pull requests are all welcome.

## Prerequisites

- macOS 14 Sonoma or later
- The latest Xcode

## Getting started

```sh
git clone https://github.com/Dronnn/notchTelePrompt.git
cd notchTelePrompt
open notchTelePrompt.xcodeproj
```

Build and run from Xcode (the standard scheme). The app is a sandboxed menu-bar app, so it appears in the menu bar rather than the Dock.

## Linting and formatting

SwiftLint and SwiftFormat run automatically in the "Lint & Format" Xcode build phase. The build surfaces any violations — please fix them before opening a pull request, so the project stays warning-free.

## Tests

Run the unit tests before opening a pull request, and add tests for any logic you change or introduce.

## Coding conventions

- **Swift 6** with strict concurrency (`complete`); aim for zero warnings.
- **MVVM** architecture; keep view logic in view models so it can be tested.
- **SwiftUI first.** Drop down to AppKit (`NSPanel`, `NSWindow`, `NSStatusItem`, `NSScreen`) only where it is required — chiefly the menu-bar item and the notch overlay panels. When you do work in AppKit, follow AppKit conventions.
- **No force-unwraps** and no force `try` unless a failure is genuinely unrecoverable. Keep safe access patterns safe.
- **Comments** are lowercase, except `MARK` and `TODO`, which stay uppercase. Prefer clear code over comments; skip obvious ones.
- Reuse existing helpers and extensions rather than duplicating them.

## Dependencies

The only third-party dependency is [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (Sindre Sorhus) for rebindable global hotkeys. **Do not add a new third-party dependency without discussing it first** in an issue — the app is sandboxed and headed for the Mac App Store, so dependencies need scrutiny.

## Commits and pull requests

- Keep commits focused, with clear messages in the imperative mood.
- Open an issue first for larger changes so we can agree on the approach.
- In the pull request, describe what changed and how you tested it, and link any related issue. The pull request template walks through this.
- Use the [issue templates](.github/ISSUE_TEMPLATE) for bug reports and feature requests.

## License

By contributing, you agree that your contributions are licensed under the project's [MIT License](LICENSE).
