// Session.swift
// Domain model for completed focus sessions

import Foundation

struct FocusSession: Identifiable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date?
    let totalFocusSeconds: Int32
    let totalBreakSeconds: Int32
    let completedIntervals: Int16
    let wasCompleted: Bool
    let workflowName: String

    var formattedFocusTime: String {
        let minutes = Int(totalFocusSeconds) / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
    }

    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startedAt)
    }

    static func from(managedObject: NSObject) -> FocusSession? {
        guard let id = (managedObject as AnyObject).value(forKey: "id") as? UUID,
              let startedAt = (managedObject as AnyObject).value(forKey: "startedAt") as? Date,
              let workflowName = (managedObject as AnyObject).value(forKey: "workflowName") as? String
        else { return nil }

        return FocusSession(
            id: id,
            startedAt: startedAt,
            endedAt: (managedObject as AnyObject).value(forKey: "endedAt") as? Date,
            totalFocusSeconds: (managedObject as AnyObject).value(forKey: "totalFocusSeconds") as? Int32 ?? 0,
            totalBreakSeconds: (managedObject as AnyObject).value(forKey: "totalBreakSeconds") as? Int32 ?? 0,
            completedIntervals: (managedObject as AnyObject).value(forKey: "completedIntervals") as? Int16 ?? 0,
            wasCompleted: (managedObject as AnyObject).value(forKey: "wasCompleted") as? Bool ?? false,
            workflowName: workflowName
        )
    }
}

// MARK: - CSV Export

extension Array where Element == FocusSession {
    func toCSV() -> String {
        var csv = "Date,Workflow,Focus Minutes,Break Minutes,Intervals,Completed\n"
        for session in self {
            let date = session.formattedDate
            let workflow = session.workflowName.replacingOccurrences(of: ",", with: ";")
            let focusMin = Int(session.totalFocusSeconds) / 60
            let breakMin = Int(session.totalBreakSeconds) / 60
            let intervals = session.completedIntervals
            let completed = session.wasCompleted ? "Yes" : "No"
            csv += "\(date),\(workflow),\(focusMin),\(breakMin),\(intervals),\(completed)\n"
        }
        return csv
    }
}
