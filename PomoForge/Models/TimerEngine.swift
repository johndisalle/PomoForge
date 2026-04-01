// TimerEngine.swift
// Pure timer state machine — no UI dependencies

import Foundation
import Combine

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case completed
}

class TimerEngine: ObservableObject {
    @Published var state: TimerState = .idle
    @Published var remainingSeconds: Int = 0
    @Published var currentIntervalIndex: Int = 0
    @Published var elapsedFocusSeconds: Int = 0
    @Published var elapsedBreakSeconds: Int = 0

    private var timer: Timer?
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
            remainingSeconds = intervals.first?.duration ?? 0
        }
        state = .running
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        stopTimer()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        startTimer()
    }

    func reset() {
        stopTimer()
        state = .idle
        currentIntervalIndex = 0
        elapsedFocusSeconds = 0
        elapsedBreakSeconds = 0
        remainingSeconds = intervals.first?.duration ?? 0
    }

    func skip() {
        advanceToNextInterval()
    }

    // MARK: - Timer Loop

    private func startTimer() {
        stopTimer()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .running else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1

            // Track elapsed time by type
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
            advanceToNextInterval()
        }
    }

    private func advanceToNextInterval() {
        let nextIndex = currentIntervalIndex + 1
        if nextIndex < intervals.count {
            currentIntervalIndex = nextIndex
            remainingSeconds = intervals[nextIndex].duration
            // Post notification for interval change (haptics, sound)
            NotificationCenter.default.post(name: .intervalChanged, object: currentInterval)
        } else {
            state = .completed
            stopTimer()
            NotificationCenter.default.post(name: .workflowCompleted, object: nil)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let intervalChanged = Notification.Name("pomoforge.intervalChanged")
    static let workflowCompleted = Notification.Name("pomoforge.workflowCompleted")
}
