// PomoForgeWidget.swift
// WidgetKit extension — "Current Session" and "Today's Focus" widgets

import WidgetKit
import SwiftUI

// MARK: - Current Session Widget

struct CurrentSessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> CurrentSessionEntry {
        CurrentSessionEntry(
            date: Date(),
            isActive: true,
            intervalType: "work",
            workflowName: "Deep Work",
            endDate: Date().addingTimeInterval(1500)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CurrentSessionEntry) -> Void) {
        let data = WidgetManager.shared.readCurrentSession()
        let entry = CurrentSessionEntry(
            date: Date(),
            isActive: data.isActive,
            intervalType: data.intervalType,
            workflowName: data.workflowName,
            endDate: data.endDate
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentSessionEntry>) -> Void) {
        let data = WidgetManager.shared.readCurrentSession()
        let entry = CurrentSessionEntry(
            date: Date(),
            isActive: data.isActive,
            intervalType: data.intervalType,
            workflowName: data.workflowName,
            endDate: data.endDate
        )
        // Refresh every 60 seconds when active
        let nextUpdate = data.isActive
            ? Calendar.current.date(byAdding: .second, value: 60, to: Date())!
            : Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CurrentSessionEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let intervalType: String
    let workflowName: String
    let endDate: Date?
}

struct CurrentSessionWidgetView: View {
    var entry: CurrentSessionEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.isActive {
            activeView
        } else {
            inactiveView
        }
    }

    private var activeView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(intervalColor)
                    .frame(width: 8, height: 8)
                Text(entry.intervalType == "work" ? "Focusing" : "Break")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if let endDate = entry.endDate {
                Text(endDate, style: .timer)
                    .font(.system(size: family == .systemSmall ? 28 : 36, weight: .thin, design: .rounded))
                    .monospacedDigit()
            }

            Text(entry.workflowName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var inactiveView: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange.opacity(0.6))
            Text("Start a session")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private var intervalColor: Color {
        switch entry.intervalType {
        case "work": return .orange
        case "break": return .green
        default: return .blue
        }
    }
}

struct CurrentSessionWidget: Widget {
    let kind: String = "CurrentSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentSessionProvider()) { entry in
            CurrentSessionWidgetView(entry: entry)
        }
        .configurationDisplayName("Current Session")
        .description("Shows your active Pomodoro timer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Today's Focus Widget

struct TodaysFocusProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodaysFocusEntry {
        TodaysFocusEntry(date: Date(), minutes: 120, sessions: 4, streak: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaysFocusEntry) -> Void) {
        let data = WidgetManager.shared.readTodaysFocus()
        completion(TodaysFocusEntry(date: Date(), minutes: data.minutes, sessions: data.sessions, streak: data.streak))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaysFocusEntry>) -> Void) {
        let data = WidgetManager.shared.readTodaysFocus()
        let entry = TodaysFocusEntry(date: Date(), minutes: data.minutes, sessions: data.sessions, streak: data.streak)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TodaysFocusEntry: TimelineEntry {
    let date: Date
    let minutes: Int
    let sessions: Int
    let streak: Int
}

struct TodaysFocusWidgetView: View {
    var entry: TodaysFocusEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("Today's Focus")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Text("\(entry.minutes)m")
                .font(.system(size: family == .systemSmall ? 32 : 40, weight: .bold, design: .rounded))

            HStack(spacing: 12) {
                Label("\(entry.sessions)", systemImage: "checkmark.circle")
                Label("\(entry.streak)d", systemImage: "bolt.fill")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct TodaysFocusWidget: Widget {
    let kind: String = "TodaysFocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaysFocusProvider()) { entry in
            TodaysFocusWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Focus")
        .description("Shows your daily focus time and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct PomoForgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        CurrentSessionWidget()
        TodaysFocusWidget()
    }
}
