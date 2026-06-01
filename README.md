# NotchPrompter

A native macOS menu-bar teleprompter that displays your script right next to the MacBook camera — in and around the display notch — so you can read while keeping natural eye contact with the lens.

Built for people who speak on camera: video recordings, online meetings, screen shares, webinars, demos, interviews, and lectures.

## Why

- **Close to the camera.** Text sits beside/below the notch (or as a slim top overlay on Macs without one), so your eyes stay near the lens.
- **Private and local.** Scripts live on your Mac. Nothing is uploaded — no scripts, no audio, no account, no analytics.
- **Best-effort invisible to capture.** The overlay asks macOS to exclude it from screen recording and sharing. This works for native capture and most apps, but **cannot be guaranteed in every third-party app** — see the in-app note.
- **Fast.** Paste a script and start reading in under a minute.

## Features (v1.0)

- Notch-aligned overlay + top-center fallback
- Plain-text editor with autosave, word count, and reading-time estimate
- Local script library (search, duplicate, favorite, recent)
- Manual scroll + fixed-speed auto-scroll (WPM / pt-per-second)
- Countdown, pause/resume, hover-to-pause, restart
- Voice-activity mode: scroll while you speak, pause on silence (on-device)
- Customizable text, colors, opacity, spacing, alignment, and presets
- Import/export `.txt` and `.md`, paste-from-clipboard, drag & drop
- Rebindable global hotkeys and menu-bar controls

## Requirements

- macOS 14 Sonoma or later
- Apple silicon or Intel Mac

## Status

In active development toward a 1.0 Mac App Store release.

Implemented so far:

- **Foundations** — sandboxed menu-bar app (no Dock icon), Swift 6 strict concurrency, SwiftLint/SwiftFormat pipeline.
- **Local persistence** — SwiftData model and script store: create, edit, search, sort, duplicate, favorite, and recent ordering.
- **Editor & library** — split-view window with a plain-text editor (live word/character count and reading-time estimate, debounced autosave) and a searchable, sortable library with favorites, duplicate/rename/delete, and a first-launch welcome.
- **Import / export** — import `.txt` / `.md` files, paste the clipboard as a new script (auto-titled), drag a file onto the editor, and export the current script — all UTF-8 with line breaks preserved.

Next up: the notch overlay window (a borderless panel that floats near the camera without stealing focus).

## License

MIT © Andreas Maier — see [LICENSE](LICENSE).
