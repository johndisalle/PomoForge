// WidgetManager.swift
// Manages shared data for WidgetKit widgets via App Groups

import Foundation
import WidgetKit

struct WidgetManager {
    static let shared = WidgetManager()
    static let appGroupId = "group.com.pomoforge.shared"

    private let defaults: UserDefaults?

    init() {
        defaults = UserDefaults(suiteName: Self.appGroupId)
    }

    // MARK: - Current Session Data (for "Current Session" widget)

    func updateCurrentSession(
        isActive: Bool,
        intervalType: String = "",
        remainingSeconds: Int = 0,
        workflowName: String = "",
        endDate: Date? = nil
    ) {
        defaults?.set(isActive, forKey: "widget_isActive")
        defaults?.set(intervalType, forKey: "widget_intervalType")
        defaults?.set(remainingSeconds, forKey: "widget_remainingSeconds")
        defaults?.set(workflowName, forKey: "widget_workflowName")
        defaults?.set(endDate, forKey: "widget_endDate")
        reloadWidgets()
    }

    func clearCurrentSession() {
        updateCurrentSession(isActive: false)
    }

    // MARK: - Today's Focus Data (for "Today's Focus" widget)

    func updateTodaysFocus(minutes: Int, sessions: Int, streak: Int) {
        defaults?.set(minutes, forKey: "widget_todayMinutes")
        defaults?.set(sessions, forKey: "widget_todaySessions")
        defaults?.set(streak, forKey: "widget_streak")
        reloadWidgets()
    }

    // MARK: - Read Data

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

    // MARK: - Reload

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
