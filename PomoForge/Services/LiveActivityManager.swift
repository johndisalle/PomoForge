// LiveActivityManager.swift
// Manages Live Activities for the Lock Screen timer display
// Requires ActivityKit and a Live Activity widget extension

import Foundation
import ActivityKit
import SwiftUI

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

// MARK: - Live Activity Manager

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var isActivityActive = false
    private var currentActivity: Activity<PomoForgeTimerAttributes>?

    func startActivity(
        workflowName: String,
        workflowId: UUID,
        remainingSeconds: Int,
        intervalType: String,
        intervalIndex: Int,
        totalIntervals: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = PomoForgeTimerAttributes(workflowId: workflowId.uuidString)
        let endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        let state = PomoForgeTimerAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            intervalType: intervalType,
            workflowName: workflowName,
            intervalIndex: intervalIndex,
            totalIntervals: totalIntervals,
            endDate: endDate
        )

        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60))

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            isActivityActive = true
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(
        remainingSeconds: Int,
        intervalType: String,
        workflowName: String,
        intervalIndex: Int,
        totalIntervals: Int
    ) {
        guard let activity = currentActivity else { return }

        let endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        let state = PomoForgeTimerAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            intervalType: intervalType,
            workflowName: workflowName,
            intervalIndex: intervalIndex,
            totalIntervals: totalIntervals,
            endDate: endDate
        )

        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60))

        Task {
            await activity.update(content)
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }

        let finalState = PomoForgeTimerAttributes.ContentState(
            remainingSeconds: 0,
            intervalType: "completed",
            workflowName: "",
            intervalIndex: 0,
            totalIntervals: 0,
            endDate: Date()
        )

        let content = ActivityContent(state: finalState, staleDate: Date())

        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 30))
            self.currentActivity = nil
            self.isActivityActive = false
        }
    }
}
