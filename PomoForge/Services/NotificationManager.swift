// NotificationManager.swift
// Local notifications for interval changes and workflow completion

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    // Schedule a notification for when the current interval ends
    func scheduleIntervalEnd(in seconds: Int, intervalType: IntervalType, nextIntervalType: IntervalType?) {
        removeAllPending()

        let content = UNMutableNotificationContent()

        switch intervalType {
        case .work:
            content.title = "Focus Complete"
            if let next = nextIntervalType {
                content.body = next == .longBreak ? "Great work! Time for a long break." : "Nice focus session! Take a break."
            } else {
                content.body = "Workflow complete! You crushed it."
            }
        case .shortBreak:
            content.title = "Break Over"
            content.body = "Ready to focus? Let's go."
        case .longBreak:
            content.title = "Long Break Over"
            content.body = "Feeling refreshed? Time to get back to it."
        }

        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(seconds, 1)), repeats: false)
        let request = UNNotificationRequest(identifier: "pomoforge.interval", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // Schedule all upcoming interval notifications for the entire workflow
    func scheduleAllIntervals(intervals: [TimerInterval], startingFrom index: Int, currentRemaining: Int) {
        removeAllPending()

        var cumulativeSeconds = currentRemaining

        for i in index..<intervals.count {
            let interval = intervals[i]
            let nextInterval: IntervalType? = (i + 1 < intervals.count) ? intervals[i + 1].type : nil

            let content = UNMutableNotificationContent()

            switch interval.type {
            case .work:
                content.title = "Focus Complete"
                if let next = nextInterval {
                    content.body = next == .longBreak ? "Great work! Time for a long break." : "Nice session! Take a short break."
                } else {
                    content.body = "Workflow complete! You crushed it."
                }
            case .shortBreak:
                content.title = "Break Over"
                content.body = "Ready to focus? Let's go."
            case .longBreak:
                content.title = "Long Break Over"
                content.body = "Feeling refreshed? Back to work."
            }

            content.sound = .default
            content.interruptionLevel = .timeSensitive

            let triggerTime = max(cumulativeSeconds, 1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(triggerTime), repeats: false)
            let request = UNNotificationRequest(identifier: "pomoforge.interval.\(i)", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)

            // Add next interval's duration
            if i + 1 < intervals.count {
                cumulativeSeconds += intervals[i + 1].duration
            }
        }
    }

    func scheduleWorkflowComplete(in seconds: Int, workflowName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Workflow Complete!"
        content.body = "\(workflowName) finished. Amazing focus session!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(seconds, 1)), repeats: false)
        let request = UNNotificationRequest(identifier: "pomoforge.complete", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func removeAllDelivered() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
