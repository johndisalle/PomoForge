// Workflow.swift
// Domain model for timer workflows

import Foundation

// MARK: - Interval Types

enum IntervalType: String, Codable, CaseIterable {
    case work
    case shortBreak = "break"
    case longBreak

    var displayName: String {
        switch self {
        case .work: return "Focus"
        case .shortBreak: return "Break"
        case .longBreak: return "Long Break"
        }
    }

    var color: String {
        switch self {
        case .work: return "timerWork"
        case .shortBreak: return "timerBreak"
        case .longBreak: return "timerLongBreak"
        }
    }
}

// MARK: - Timer Interval

struct TimerInterval: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var type: IntervalType
    var duration: Int // seconds

    var durationMinutes: Int {
        get { duration / 60 }
        set { duration = newValue * 60 }
    }

    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        if seconds == 0 {
            return "\(minutes)m"
        }
        return "\(minutes)m \(seconds)s"
    }

    // Decode from the simplified JSON stored in Core Data
    enum CodingKeys: String, CodingKey {
        case type, duration
    }

    init(type: IntervalType, duration: Int) {
        self.type = type
        self.duration = duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(IntervalType.self, forKey: .type)
        self.duration = try container.decode(Int.self, forKey: .duration)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(duration, forKey: .duration)
    }
}

// MARK: - Workflow Model

struct Workflow: Identifiable, Equatable {
    let id: UUID
    var name: String
    var intervals: [TimerInterval]
    var isDefault: Bool
    let createdAt: Date

    var totalDuration: Int {
        intervals.reduce(0) { $0 + $1.duration }
    }

    var totalFocusDuration: Int {
        intervals.filter { $0.type == .work }.reduce(0) { $0 + $1.duration }
    }

    var formattedTotal: String {
        let minutes = totalDuration / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    var intervalSummary: String {
        let workCount = intervals.filter { $0.type == .work }.count
        let breakCount = intervals.filter { $0.type != .work }.count
        return "\(workCount) focus · \(breakCount) breaks"
    }

    static let defaultWorkflow = Workflow(
        id: UUID(),
        name: "Classic Pomodoro",
        intervals: [
            TimerInterval(type: .work, duration: 1500),
            TimerInterval(type: .shortBreak, duration: 300),
            TimerInterval(type: .work, duration: 1500),
            TimerInterval(type: .shortBreak, duration: 300),
            TimerInterval(type: .work, duration: 1500),
            TimerInterval(type: .shortBreak, duration: 300),
            TimerInterval(type: .work, duration: 1500),
            TimerInterval(type: .longBreak, duration: 900)
        ],
        isDefault: true,
        createdAt: Date()
    )

    // MARK: - Core Data Conversion

    static func from(managedObject: NSObject) -> Workflow? {
        guard let id = (managedObject as AnyObject).value(forKey: "id") as? UUID,
              let name = (managedObject as AnyObject).value(forKey: "name") as? String,
              let isDefault = (managedObject as AnyObject).value(forKey: "isDefault") as? Bool,
              let createdAt = (managedObject as AnyObject).value(forKey: "createdAt") as? Date,
              let data = (managedObject as AnyObject).value(forKey: "intervalsData") as? Data
        else { return nil }

        let intervals = (try? JSONDecoder().decode([TimerInterval].self, from: data)) ?? []
        return Workflow(id: id, name: name, intervals: intervals, isDefault: isDefault, createdAt: createdAt)
    }
}
