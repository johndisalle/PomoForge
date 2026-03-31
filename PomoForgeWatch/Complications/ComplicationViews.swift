// ComplicationViews.swift
// Apple Watch complications for PomoForge

import SwiftUI
import WidgetKit

// MARK: - Watch Complication Provider

struct PomoForgeComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: Date(), remainingMinutes: 25, intervalType: "work", isActive: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        let entry = ComplicationEntry(date: Date(), remainingMinutes: 0, intervalType: "idle", isActive: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let entry = ComplicationEntry(date: Date(), remainingMinutes: 0, intervalType: "idle", isActive: false)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let remainingMinutes: Int
    let intervalType: String
    let isActive: Bool
}

// MARK: - Complication Views

struct CircularComplicationView: View {
    let entry: ComplicationEntry

    var body: some View {
        ZStack {
            if entry.isActive {
                Gauge(value: Double(entry.remainingMinutes), in: 0...60) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                } currentValueLabel: {
                    Text("\(entry.remainingMinutes)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .gaugeStyle(.circular)
                .tint(.orange)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Start")
                        .font(.system(size: 10))
                }
            }
        }
    }
}

struct RectangularComplicationView: View {
    let entry: ComplicationEntry

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)

            if entry.isActive {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.intervalType == "work" ? "Focusing" : "Break")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(entry.remainingMinutes)m left")
                        .font(.headline)
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text("PomoForge")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Tap to start")
                        .font(.headline)
                }
            }
        }
    }
}

// MARK: - Complication Widget

struct PomoForgeComplication: Widget {
    let kind = "PomoForgeComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomoForgeComplicationProvider()) { entry in
            CircularComplicationView(entry: entry)
        }
        .configurationDisplayName("PomoForge Timer")
        .description("Shows remaining timer on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
