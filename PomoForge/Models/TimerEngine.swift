// TimerEngine.swift
// Pure timer state machine with reliable main-thread updates

import Foundation
import Combine

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case completed
}

@MainActor
class TimerEngine: ObservableObject {
    @Published var state: TimerState = .idle
    @Published var remainingSeconds: Int = 0
    @Published var currentIntervalIndex: Int = 0
    @Published var elapsedFocusSeconds: Int = 0
    @Published var elapsedBreakSeconds: Int = 0

    private var displayLink: CADisplayLink?
    private var lastTickTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private(set) var intervals: [TimerInterval] = []

    var currentInterval: TimerInterval? {
        guard currentIntervalIndex < intervals.count else { return nil }
        return intervals[currentIntervalIndex]
    }

    var progress: Double {
        guard let interval = currentInterval, interval.duration > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(interval.duration))
    }

    var overallProgress: Double {
        let totalDuration = intervals.reduce(0) { $0 + $1.duration }
        guard totalDuration > 0 else { return 0 }
        let completedDuration = intervals.prefix(currentIntervalIndex).reduce(0) { $0 + $1.duration }
        let currentDuration = (currentInterval?.duration ?? 0) - remainingSeconds
        return Double(completedDuration + currentDuration) / Double(totalDuration)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var completedIntervalsCount: Int {
        currentIntervalIndex
    }

    // MARK: - Control

    func load(intervals: [TimerInterval]) {
        self.intervals = intervals
        reset()
    }

    func start() {
        guard state != .running else { return }
        if state == .idle || state == .completed {
            currentIntervalIndex = 0
            elapsedFocusSeconds = 0
            elapsedBreakSeconds = 0
            if let first = intervals.first {
                remainingSeconds = first.duration
            }
        }
        state = .running
        startTicking()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        stopTicking()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startTicking()
    }

    func reset() {
        stopTicking()
        state = .idle
        currentIntervalIndex = 0
        elapsedFocusSeconds = 0
        elapsedBreakSeconds = 0
        remainingSeconds = intervals.first?.duration ?? 0
    }

    func skip() {
        advanceToNextInterval()
    }

    // MARK: - Reliable Timer using CADisplayLink

    private func startTicking() {
        stopTicking()
        accumulatedTime = 0
        lastTickTime = Date()

        let link = CADisplayLink(target: TickTarget(engine: self), selector: #selector(TickTarget.tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 1, maximum: 15, preferred: 2)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopTicking() {
        displayLink?.invalidate()
        displayLink = nil
        lastTickTime = nil
        accumulatedTime = 0
    }

    fileprivate func handleTick() {
        guard state == .running else { return }

        let now = Date()
        guard let last = lastTickTime else {
            lastTickTime = now
            return
        }

        accumulatedTime += now.timeIntervalSince(last)
        lastTickTime = now

        // Process whole seconds
        while accumulatedTime >= 1.0 && remainingSeconds > 0 {
            accumulatedTime -= 1.0
            remainingSeconds -= 1

            if let interval = currentInterval {
                switch interval.type {
                case .work:
                    elapsedFocusSeconds += 1
                case .shortBreak, .longBreak:
                    elapsedBreakSeconds += 1
                }
            }
        }

        if remainingSeconds == 0 {
            accumulatedTime = 0
            advanceToNextInterval()
        }
    }

    private func advanceToNextInterval() {
        let nextIndex = currentIntervalIndex + 1
        if nextIndex < intervals.count {
            currentIntervalIndex = nextIndex
            remainingSeconds = intervals[nextIndex].duration
            NotificationCenter.default.post(name: .intervalChanged, object: currentInterval)
        } else {
            state = .completed
            stopTicking()
            NotificationCenter.default.post(name: .workflowCompleted, object: nil)
        }
    }
}

// CADisplayLink target (avoids retain cycle)
private class TickTarget {
    weak var engine: TimerEngine?

    init(engine: TimerEngine) {
        self.engine = engine
    }

    @objc func tick() {
        Task { @MainActor in
            engine?.handleTick()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let intervalChanged = Notification.Name("pomoforge.intervalChanged")
    static let workflowCompleted = Notification.Name("pomoforge.workflowCompleted")
}
