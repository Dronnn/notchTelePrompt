//
//  ScrollEngine.swift
//  notchTelePrompt
//
//  Created by Andreas Maier.
//  Copyright © 2026 Andreas Maier. All rights reserved.
//

import QuartzCore

/// drives the prompter's auto-scroll: owns the scroll offset, the playback state and the countdown,
/// and integrates motion from wall-clock time deltas so scrolling never drifts (spec §46).
///
/// the timing core is `advance(to:)`, which the main-actor ticker calls each frame with a
/// `CACurrentMediaTime()` timestamp; tests call it with synthetic timestamps. the ticker itself is a
/// `Task` loop (a real `CADisplayLink` would be a nice-to-have; the loop keeps the seam testable and
/// is paused whenever nothing is moving, so idle CPU stays low per §38).
@MainActor
@Observable
final class ScrollEngine {
    // MARK: - Outputs

    /// distance the content has scrolled upward, in points; pinned to `0...maxOffset`.
    private(set) var offset: Double = 0

    /// the current playback lifecycle state.
    private(set) var state: PlaybackState = .idle

    /// whole seconds left in the pre-start countdown; 0 when not counting down.
    private(set) var countdownRemaining = 0

    // MARK: - Inputs (driven by the view as it lays out)

    /// the rendered line stack's total height; computed from metrics by the view model, not measured.
    var contentHeight: Double = 0

    /// the visible viewport height, measured by the view.
    var viewportHeight: Double = 0

    /// geometry used by the layout metrics; kept in sync with the active font size / line spacing.
    var fontSize = PrompterFontSize.default
    var lineSpacing = Double(PrompterStyle.lineSpacing)

    /// auto-scroll speed in points-per-second.
    var pointsPerSecond: Double = 0

    /// how long to wait before auto-resuming once a hover ends (only if it was playing before).
    var hoverResumeDelay: Duration = .seconds(1)

    // MARK: - Derived

    /// the largest reachable offset for the current geometry.
    var maxOffset: Double {
        PrompterLayoutMetrics.maxOffset(
            contentHeight: contentHeight,
            viewportHeight: viewportHeight,
            fontSize: fontSize,
            lineSpacing: lineSpacing
        )
    }

    /// scroll progress in `0...1`.
    var progress: Double {
        let limit = maxOffset
        guard limit > 0 else {
            return 0
        }
        return min(max(offset / limit, 0), 1)
    }

    // MARK: - Private timing state

    /// the timestamp of the last `advance(to:)`; nil until the first call after motion starts.
    private var lastTimestamp: TimeInterval?

    /// the configured countdown length in seconds, set on start; nil when no countdown is running.
    private var countdownSeconds: Int?

    /// the timestamp the countdown should reach zero, fixed lazily on the first countdown `advance`
    /// so it tracks whatever clock drives the engine (real `CACurrentMediaTime()` or a synthetic one).
    private var countdownEndTimestamp: TimeInterval?

    /// the ticker task that pumps `advance(to:)` while playing or counting down.
    private var ticker: Task<Void, Never>?

    /// whether the pointer is currently over the prompter.
    private var isHovering = false

    /// whether playback was active when the current hover began (so we only auto-resume real playback).
    private var wasPlayingBeforeHover = false

    /// the pending delayed-resume task scheduled when a hover ends.
    private var resumeTask: Task<Void, Never>?

    /// whether the engine runs its own frame ticker. disabled in tests, which drive `advance(to:)`
    /// with synthetic timestamps so timing is deterministic.
    @ObservationIgnored private let autoTick: Bool

    // MARK: - Lifecycle

    init(autoTick: Bool = true) {
        self.autoTick = autoTick
    }

    // no deinit cancellation needed: both the ticker and the resume task capture self weakly and return
    // as soon as self is gone, so they self-terminate without a nonisolated deinit touching them.

    // MARK: - Drift-free core

    /// advances the engine to the given absolute timestamp using the delta since the previous call.
    /// while `.playing` it integrates `pointsPerSecond * delta` into the offset (clamped, finishing at
    /// the end); while `.countdown` it derives the remaining seconds from wall-clock time. computing
    /// from accumulated wall-time rather than fixed per-tick steps is what keeps scrolling drift-free.
    func advance(to timestamp: TimeInterval) {
        defer { lastTimestamp = timestamp }
        guard let previous = lastTimestamp else {
            // first sample after (re)starting motion: seed the clock. if a countdown is running, anchor
            // its end to this first timestamp so it spans its full duration from frame one — otherwise the
            // gap before the first real delta would be shaved off the countdown.
            if state == .countdown, let seconds = countdownSeconds, seconds > 0, countdownEndTimestamp == nil {
                countdownEndTimestamp = timestamp + TimeInterval(seconds)
            }
            return
        }
        let delta = timestamp - previous
        guard delta > 0 else {
            return
        }

        switch state {
        case .playing:
            advancePlaying(delta: delta)
        case .countdown:
            advanceCountdown(now: timestamp)
        case .idle, .paused, .finished:
            break
        }
    }

    private func advancePlaying(delta: TimeInterval) {
        let limit = maxOffset
        let next = offset + pointsPerSecond * delta
        if next >= limit {
            offset = limit
            transition(.reachedEnd)
        } else {
            offset = max(next, 0)
        }
    }

    private func advanceCountdown(now: TimeInterval) {
        guard let seconds = countdownSeconds, seconds > 0 else {
            transition(.countdownFinished)
            return
        }
        // fix the end instant on the first countdown tick so it tracks this run's clock.
        let end = countdownEndTimestamp ?? {
            let value = now + TimeInterval(seconds)
            countdownEndTimestamp = value
            return value
        }()
        let remaining = end - now
        if remaining <= 0 {
            countdownRemaining = 0
            transition(.countdownFinished)
        } else {
            countdownRemaining = Int(remaining.rounded(.up))
        }
    }

    // MARK: - Public controls

    /// starts playback, optionally running a countdown first (spec §17).
    func start(countdown: CountdownOption) {
        offset = min(max(offset, 0), maxOffset)
        countdownEndTimestamp = nil
        if let seconds = countdown.seconds, seconds > 0 {
            countdownSeconds = seconds
            countdownRemaining = seconds
            transition(.start)
        } else {
            // no countdown: enter then immediately leave the countdown state, landing in playing.
            countdownSeconds = nil
            countdownRemaining = 0
            transition(.start)
            transition(.countdownFinished)
        }
    }

    func pause() {
        transition(.pause)
    }

    func resume() {
        transition(.resume)
    }

    /// stops playback and returns to the top.
    func stop() {
        transition(.stop)
        offset = 0
        countdownRemaining = 0
        countdownSeconds = nil
        countdownEndTimestamp = nil
    }

    /// restarts from the beginning, re-running the countdown if one is configured.
    func restart(countdown: CountdownOption) {
        offset = 0
        start(countdown: countdown)
    }

    /// jumps to the top without changing the playback state.
    func jumpToStart() {
        offset = 0
    }

    /// jumps to the end without changing the playback state.
    func jumpToEnd() {
        offset = maxOffset
    }

    /// toggles between playing and paused; from idle/finished it starts with no countdown.
    func togglePlayPause() {
        switch state {
        case .playing:
            pause()
        case .paused:
            resume()
        case .idle, .finished:
            start(countdown: .off)
        case .countdown:
            break
        }
    }

    /// sets the auto-scroll speed (live-adjustable while playing).
    func setSpeed(_ speed: ScrollSpeed) {
        pointsPerSecond = speed.pointsPerSecond
    }

    /// manual scroll: shifts the offset by `deltaPoints`, clamped. since the playing integrator works
    /// from per-tick deltas against the running clock, the change is picked up smoothly on the next
    /// tick without a stale jump, so no explicit time-origin rebase is required here.
    func nudge(by deltaPoints: Double) {
        offset = min(max(offset + deltaPoints, 0), maxOffset)
    }

    /// hover-to-pause (spec §18-adjacent): pauses while hovering; when the hover ends, auto-resumes
    /// after `hoverResumeDelay` only if playback was active when the hover began.
    func setHovering(_ hovering: Bool) {
        guard hovering != isHovering else {
            return
        }
        isHovering = hovering
        if hovering {
            resumeTask?.cancel()
            resumeTask = nil
            wasPlayingBeforeHover = isPlaying
            if isPlaying {
                pause()
            }
        } else {
            guard wasPlayingBeforeHover else {
                return
            }
            scheduleDelayedResume()
        }
    }

    private func scheduleDelayedResume() {
        resumeTask?.cancel()
        let delay = hoverResumeDelay
        resumeTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else {
                return
            }
            if !isHovering, isPaused {
                resume()
            }
            wasPlayingBeforeHover = false
        }
    }

    // MARK: - State predicates

    private var isPlaying: Bool {
        if case .playing = state { return true }
        return false
    }

    private var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    private var isMoving: Bool {
        switch state {
        case .playing, .countdown:
            true
        case .idle, .paused, .finished:
            false
        }
    }

    // MARK: - Ticker

    /// the per-frame loop; reseeds the clock on (re)start so the first delta is from "now", and stops
    /// itself the moment the engine is no longer moving. when `autoTick` is off (tests) the clock is
    /// still reseeded but no driver task runs, so synthetic `advance(to:)` calls stay deterministic.
    private func startTicker() {
        guard ticker == nil else {
            return
        }
        lastTimestamp = nil
        guard autoTick else {
            return
        }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }
                guard isMoving else {
                    return
                }
                advance(to: CACurrentMediaTime())
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
        lastTimestamp = nil
    }

    /// applies an event through the machine and (re)acts to ticker needs in one place.
    private func transition(_ event: PlaybackEvent) {
        let newState = PlaybackStateMachine.next(from: state, on: event)
        state = newState
        if isMoving {
            startTicker()
        } else {
            stopTicker()
        }
    }
}
