// LiveActivityView.swift
// Live Activity UI for Lock Screen and Dynamic Island

import SwiftUI
import WidgetKit
import ActivityKit

struct PomoForgeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomoForgeTimerAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Label(intervalLabel(context.state.intervalType), systemImage: intervalIcon(context.state.intervalType))
                        .font(.caption)
                        .foregroundStyle(intervalColor(context.state.intervalType))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.intervalIndex + 1)/\(context.state.totalIntervals)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.endDate, style: .timer)
                        .font(.system(size: 36, weight: .thin, design: .rounded))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.workflowName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: intervalIcon(context.state.intervalType))
                    .foregroundStyle(intervalColor(context.state.intervalType))
                    .font(.caption)
            } compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .font(.caption.monospacedDigit())
                    .frame(width: 56)
            } minimal: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption2)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<PomoForgeTimerAttributes>) -> some View {
        HStack(spacing: 16) {
            // Interval indicator
            VStack(spacing: 4) {
                Image(systemName: intervalIcon(context.state.intervalType))
                    .font(.title2)
                    .foregroundStyle(intervalColor(context.state.intervalType))
                Text(intervalLabel(context.state.intervalType))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)

            // Timer countdown
            VStack(spacing: 2) {
                Text(context.state.endDate, style: .timer)
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .monospacedDigit()
                Text(context.state.workflowName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Progress indicator
            VStack(spacing: 4) {
                Text("\(context.state.intervalIndex + 1)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("of \(context.state.totalIntervals)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
    }

    // MARK: - Helpers

    private func intervalLabel(_ type: String) -> String {
        switch type {
        case "work": return "Focus"
        case "break": return "Break"
        case "longBreak": return "Long Break"
        default: return "Done"
        }
    }

    private func intervalIcon(_ type: String) -> String {
        switch type {
        case "work": return "flame.fill"
        case "break": return "leaf.fill"
        case "longBreak": return "moon.fill"
        default: return "checkmark.circle.fill"
        }
    }

    private func intervalColor(_ type: String) -> Color {
        switch type {
        case "work": return .orange
        case "break": return .green
        case "longBreak": return .blue
        default: return .gray
        }
    }
}
