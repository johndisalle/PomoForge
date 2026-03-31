// SharedTypes.swift
// Shared between iOS app and Widget extension
// IMPORTANT: Add this file to BOTH the PomoForge AND PomoForgeWidgetExtension targets in Xcode

import Foundation
import ActivityKit

// MARK: - Live Activity Attributes

struct PomoForgeTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var intervalType: String // "work", "break", "longBreak"
        var workflowName: String
        var intervalIndex: Int
        var totalIntervals: Int
        var endDate: Date
    }

    var workflowId: String
}

// MARK: - Widget Data Reader (App Groups)

struct WidgetDataReader {
    static let shared = WidgetDataReader()
    static let appGroupId = "group.com.pomoforge.shared"

    private let defaults: UserDefaults?

    init() {
        defaults = UserDefaults(suiteName: Self.appGroupId)
    }

    func readCurrentSession() -> (isActive: Bool, intervalType: String, remainingSeconds: Int, workflowName: String, endDate: Date?) {
        let isActive = defaults?.bool(forKey: "widget_isActive") ?? false
        let intervalType = defaults?.string(forKey: "widget_intervalType") ?? ""
        let remaining = defaults?.integer(forKey: "widget_remainingSeconds") ?? 0
        let name = defaults?.string(forKey: "widget_workflowName") ?? ""
        let endDate = defaults?.object(forKey: "widget_endDate") as? Date
        return (isActive, intervalType, remaining, name, endDate)
    }

    func readTodaysFocus() -> (minutes: Int, sessions: Int, streak: Int) {
        let minutes = defaults?.integer(forKey: "widget_todayMinutes") ?? 0
        let sessions = defaults?.integer(forKey: "widget_todaySessions") ?? 0
        let streak = defaults?.integer(forKey: "widget_streak") ?? 0
        return (minutes, sessions, streak)
    }
}
