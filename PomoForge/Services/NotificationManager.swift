// NotificationManager.swift
// Local notifications for intervals, daily reminders, and streak protection

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

    // MARK: - Interval Notifications

    func scheduleAllIntervals(intervals: [TimerInterval], startingFrom index: Int, currentRemaining: Int) {
        // Only remove interval-specific notifications, not daily reminders
        removePending(withPrefix: "pomoforge.interval")

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

            if i + 1 < intervals.count {
                cumulativeSeconds += intervals[i + 1].duration
            }
        }
    }

    // MARK: - Daily Reminder

    func scheduleDailyReminder(at hour: Int, minute: Int) {
        removePending(withPrefix: "pomoforge.daily")

        let content = UNMutableNotificationContent()
        content.title = "Time to Focus"
        content.body = "Your focus session is waiting. Even 25 minutes makes a difference."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "pomoforge.daily.reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func removeDailyReminder() {
        removePending(withPrefix: "pomoforge.daily")
    }

    // MARK: - Streak Protection

    func scheduleStreakReminder(currentStreak: Int) {
        removePending(withPrefix: "pomoforge.streak")

        guard currentStreak > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't Break Your Streak!"
        if currentStreak >= 7 {
            content.body = "You've focused \(currentStreak) days in a row — that's incredible. Keep it alive today!"
        } else {
            content.body = "You're on a \(currentStreak)-day streak. Complete one session to keep it going!"
        }
        content.sound = .default

        // Schedule for 8 PM today if no session completed
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "pomoforge.streak.reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelStreakReminder() {
        removePending(withPrefix: "pomoforge.streak")
    }

    // MARK: - Cleanup

    func removePending(withPrefix prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func removeAllDelivered() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
