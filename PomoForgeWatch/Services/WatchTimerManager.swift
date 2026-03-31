// WatchTimerManager.swift
// Watch-specific timer manager (standalone, syncs via WatchConnectivity if needed)

import SwiftUI
import Combine
import WatchKit

class WatchTimerManager: ObservableObject {
    @Published var remainingSeconds: Int = 1500
    @Published var isRunning = false
    @Published var isActive = false
    @Published var currentIntervalIndex = 0
    @Published var workflowName = "Classic Pomodoro"

    private var timer: Timer?

    // Default workflow intervals (simple 25/5 x4)
    private let intervals: [(type: String, duration: Int)] = [
        ("work", 1500),
        ("break", 300),
        ("work", 1500),
        ("break", 300),
        ("work", 1500),
        ("break", 300),
        ("work", 1500),
        ("longBreak", 900)
    ]

    var currentInterval: (type: String, duration: Int) {
        guard currentIntervalIndex < intervals.count else {
            return ("work", 1500)
        }
        return intervals[currentIntervalIndex]
    }

    var progress: Double {
        guard currentInterval.duration > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(currentInterval.duration))
    }

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var currentIntervalLabel: String {
        switch currentInterval.type {
        case "work": return "FOCUS"
        case "break": return "BREAK"
        case "longBreak": return "LONG BREAK"
        default: return "FOCUS"
        }
    }

    var intervalColor: Color {
        switch currentInterval.type {
        case "work": return .orange
        case "break": return .green
        case "longBreak": return .blue
        default: return .orange
        }
    }

    func start() {
        if !isActive {
            currentIntervalIndex = 0
            remainingSeconds = intervals[0].duration
        }
        isRunning = true
        isActive = true
        startTimer()
        WKInterfaceDevice.current().play(.start)
    }

    func pause() {
        isRunning = false
        stopTimer()
        WKInterfaceDevice.current().play(.click)
    }

    func reset() {
        stopTimer()
        isRunning = false
        isActive = false
        currentIntervalIndex = 0
        remainingSeconds = intervals[0].duration
        WKInterfaceDevice.current().play(.retry)
    }

    func skip() {
        advanceInterval()
        WKInterfaceDevice.current().play(.click)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isRunning else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds == 0 {
            advanceInterval()
        }
    }

    private func advanceInterval() {
        let next = currentIntervalIndex + 1
        if next < intervals.count {
            currentIntervalIndex = next
            remainingSeconds = intervals[next].duration
            WKInterfaceDevice.current().play(.notification)
        } else {
            // Workflow complete
            isRunning = false
            isActive = false
            WKInterfaceDevice.current().play(.success)
        }
    }
}
