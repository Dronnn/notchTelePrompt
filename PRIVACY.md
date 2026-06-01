# Privacy

NotchPrompter is private and local by design. Your scripts stay on your Mac, and the app does not collect, upload, or track anything about you or your content.

## What the app handles

- **Your scripts.** Scripts you create or import live locally on your Mac in the app's own storage. They never leave your device.
- **Transient, on-device audio analysis.** When you turn on voice-follow, the app reads the microphone only to detect whether you are currently speaking. This analysis happens entirely on-device.

## What the app never does

- No scripts are uploaded.
- No audio is recorded or sent anywhere.
- No account, sign-in, or cloud service.
- No analytics, telemetry, or usage tracking.
- No third-party SDKs that phone home.

## Microphone

The microphone is accessed **only after you turn on voice-follow**, and only for as long as that mode is active. macOS will ask for permission the first time. If you never enable voice-follow, the app does not touch the microphone.

## On-device voice-activity detection

Voice-follow uses simple, energy-based voice-activity detection that runs locally on your Mac. It looks at whether sound is present to decide when to scroll and when to pause on silence. **No audio is recorded, stored, transcribed, or transmitted** — the app does not keep any of it.

## Screen-capture exclusion

The prompter overlay asks macOS to exclude it from screen recordings and screen sharing (best-effort). This works for native macOS capture and most apps. However, macOS does **not** guarantee this exclusion in every third-party recorder or virtual-camera app, so the overlay may still appear in some of them. Test your specific setup before relying on it.

## App Store

Because the app collects and uploads nothing, its App Store listing is **Data Not Collected**.

## Contact

Questions about privacy? Open an issue at [github.com/Dronnn/notchTelePrompt](https://github.com/Dronnn/notchTelePrompt/issues).
