// HistoryView.swift
// Session history with SwiftUI Charts, streak counter, CSV export

import SwiftUI
import Charts
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var sessions: [FocusSession] = []
    @State private var chartRange: ChartRange = .week
    @State private var showingExportSheet = false
    @State private var showingPaywall = false
    @State private var csvURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary cards
                    summaryCards

                    // Chart section
                    chartSection

                    // Session list
                    sessionList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        if subscriptionManager.tier == .pro {
                            exportCSV()
                        } else {
                            showingPaywall = true
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = csvURL {
                    ShareSheet(items: [url])
                }
            }
            .onAppear { loadSessions() }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Today",
                value: "\(todayFocusMinutes)m",
                subtitle: "focus time",
                icon: "flame.fill",
                color: .orange
            )
            SummaryCard(
                title: "Streak",
                value: "\(currentStreak)",
                subtitle: streakSubtitle,
                icon: "bolt.fill",
                color: .yellow
            )
            SummaryCard(
                title: "Total",
                value: totalFormatted,
                subtitle: "all time",
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Focus Time")
                    .font(.headline)
                Spacer()
                Picker("Range", selection: $chartRange) {
                    ForEach(ChartRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if subscriptionManager.tier == .pro || chartRange == .week {
                Chart(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: chartRange == .week ? .dateTime.weekday(.abbreviated) : .dateTime.day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes)m")
                            }
                        }
                    }
                }
            } else {
                // Locked chart for free users beyond weekly view
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(height: 180)

                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                        Text("Upgrade to Pro for full charts")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }
                .onTapGesture { showingPaywall = true }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Session List

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange.opacity(0.4))
                    Text("Your first session awaits")
                        .font(.headline)
                    Text("Complete a focus session and your\nhistory will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(sessions.prefix(50)) { session in
                    SessionRow(session: session)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Data

    private var todayFocusMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions
            .filter { $0.startedAt >= today }
            .reduce(0) { $0 + Int($1.totalFocusSeconds) } / 60
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        let daySet = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })

        while daySet.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    private var streakSubtitle: String {
        currentStreak == 1 ? "day" : "days"
    }

    private var totalFormatted: String {
        let totalMinutes = sessions.reduce(0) { $0 + Int($1.totalFocusSeconds) } / 60
        if totalMinutes >= 60 {
            return "\(totalMinutes / 60)h"
        }
        return "\(totalMinutes)m"
    }

    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let days: Int
        switch chartRange {
        case .week: days = 7
        case .month: days = 30
        case .year: days = 365
        }

        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date()))!
        var dataMap: [Date: Int] = [:]

        for i in 0..<days {
            let day = calendar.date(byAdding: .day, value: i, to: startDate)!
            dataMap[day] = 0
        }

        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            if day >= startDate {
                dataMap[day, default: 0] += Int(session.totalFocusSeconds) / 60
            }
        }

        return dataMap.sorted { $0.key < $1.key }.map {
            ChartDataPoint(date: $0.key, minutes: $0.value)
        }
    }

    // MARK: - Actions

    private func loadSessions() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDSession")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]

        do {
            let results = try viewContext.fetch(request)
            sessions = results.compactMap { FocusSession.from(managedObject: $0) }
        } catch {
            print("Failed to load sessions: \(error)")
        }

        // Update widget data
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = sessions.filter { $0.startedAt >= today }
        WidgetManager.shared.updateTodaysFocus(
            minutes: todayFocusMinutes,
            sessions: todaySessions.count,
            streak: currentStreak
        )
    }

    private func exportCSV() {
        let csv = sessions.toCSV()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PomoForge_Sessions.csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            csvURL = tempURL
            showingExportSheet = true
        } catch {
            print("CSV export failed: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct ChartDataPoint {
    let date: Date
    let minutes: Int
}

enum ChartRange: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }
    var label: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .year: return "Y"
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workflowName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.formattedFocusTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)

                HStack(spacing: 4) {
                    if session.wasCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Text("\(session.completedIntervals) intervals")
                        .foregroundStyle(.tertiary)
                }
                .font(.caption2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
