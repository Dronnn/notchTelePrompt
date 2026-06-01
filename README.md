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
- **Prompter overlay** — a borderless, non-activating panel that floats the script around the camera (centered below the notch) on the built-in display, above other apps and without stealing focus. Drag it anywhere, resize it from any edge or corner like a normal window, and snap it back to the notch; close and reopen it from on-screen controls or the menu bar. It asks macOS to stay out of screen captures (best-effort; not guaranteed — see the in-app note). Launch it from the editor's Start Prompter button or the menu-bar Show Prompter item.

- **Prompter display** — large readable text with the current line emphasized and the rest gently dimmed, paragraphs and line breaks preserved, plus a subtle progress bar — tuned for reading at a glance near the camera. Text size is adjustable with +/- controls in both the editor and the overlay, saved per script.

- **Prompt sets & session navigator** — group prompts into reusable, ordered sets and run a session from a small floating navigator docked to the left, listing the set's prompts by number; click one to show it in the prompter, step next/previous, and reorder by dragging. Build and edit sets from a dedicated Sets section in the main window; reordering stays in sync across both.

- **Scroll engine & playback** — drift-free, time-based auto-scroll at an adjustable speed, with a pre-roll countdown, play/pause, restart, hover-to-pause, and manual wheel/trackpad scrolling — all from the overlay's hover controls.

- **Menu-bar controls & global hotkeys** — run the prompter from the menu bar (start/pause, restart, stop, open recent, snap to notch, mini controls) or from rebindable global hotkeys that work even when another app has focus — show/hide, start/pause, restart, and speed up/down — plus optional next/previous-script and open-editor bindings. Rebind everything in a Shortcuts preferences pane. An optional floating mini control panel mirrors the playback buttons, and in-app shortcuts cover Start Prompter and text size.

- **Voice-follow (on-device)** — turn on voice mode and the prompter scrolls while you speak and pauses when you stop, using on-device voice-activity detection (energy with hysteresis and a short silence delay). Nothing is recorded or sent anywhere, and the microphone is accessed only after you enable it. A subtle mic indicator shows it is listening and brightens when it hears you.

Next up: a preferences window (general, prompter, voice sensitivity, shortcuts, privacy).

## License

MIT © Andreas Maier — see [LICENSE](LICENSE).
