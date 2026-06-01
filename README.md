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
- **Prompter overlay** — a borderless, non-activating panel that floats the script around the camera (centered below the notch) on the built-in display, above other apps and without stealing focus. Drag it anywhere, resize it from any edge or corner like a normal window (it remembers its size across launches), and snap it back to the notch. An always-visible control row in the top-right plays/pauses, restarts, adjusts speed and text size, starts/stops voice-follow, toggles the set navigator, the mini control panel, the library and preferences, snaps to the notch, and closes the overlay. It asks macOS to stay out of screen captures (best-effort; not guaranteed — see the in-app note). Launch it from the editor's Start Prompter button or the menu-bar Show Prompter item.

- **Prompter display** — large readable text with the reading line locked to the exact center of the window: the line stack scrolls behind a fixed center band while everything outside it is dimmed, so the current line never drifts. The first line starts centered and the last ends centered, with empty top/bottom halves acting as overscroll. Paragraphs and line breaks are preserved, with a subtle progress bar — tuned for reading at a glance near the camera. Text size is one global setting, adjustable with +/- controls in the editor and the overlay and in preferences.

- **Prompt sets & session navigator** — group prompts into reusable, ordered sets and run a session from a small floating navigator docked to the left, listing the set's prompts by number; click one to show it in the prompter, step next/previous, and reorder by dragging. Build and edit sets from a dedicated Sets section in the main window; reordering stays in sync across both.

- **Scroll engine & playback** — drift-free, time-based auto-scroll at an adjustable speed, with a pre-roll countdown, play/pause, restart, hover-to-pause, and manual wheel/trackpad scrolling — all from the overlay's hover controls.

- **Menu-bar controls & global hotkeys** — run the prompter from the menu bar (start/pause, restart, stop, open recent, snap to notch, mini controls) or from rebindable global hotkeys that work even when another app has focus — show/hide, start/pause, restart, and speed up/down — plus optional next/previous-script and open-editor bindings. Rebind everything in a Shortcuts preferences pane. An optional floating mini control panel mirrors the playback buttons, and in-app shortcuts cover Start Prompter and text size.

- **Voice-follow (on-device)** — turn on voice mode and the prompter scrolls while you speak and pauses when you stop, using on-device voice-activity detection (energy with hysteresis and a short silence delay). Nothing is recorded or sent anywhere, and the microphone is accessed only after you enable it. A subtle mic indicator shows it is listening and brightens when it hears you.

- **Preferences** — a settings window with General (launch at login, show in the Dock, reopen the last prompter, open the editor on launch), Prompter (default text size, colour, alignment, background opacity, line spacing, scroll speed and countdown, plus quick presets), Voice (a single sensitivity slider, silence delay, pause-on-silence and the microphone status), Shortcuts (rebind every hotkey), and Privacy (a local-only statement, the screen-capture caveat, export all scripts, and clear local data). Appearance and voice settings take effect live, and everything persists across launches.

Next up: error handling, accessibility and localization polish.

## License

MIT © Andreas Maier — see [LICENSE](LICENSE).
