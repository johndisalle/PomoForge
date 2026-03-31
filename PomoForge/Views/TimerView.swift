// TimerView.swift
// Main countdown screen with circular progress, workflow selector, Live Activity support

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var liveActivityManager = LiveActivityManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient based on interval type
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Workflow selector
                    workflowPicker

                    Spacer()

                    // Interval indicator
                    intervalLabel

                    // Circular timer
                    timerCircle

                    // Time display
                    timeDisplay

                    // Progress dots
                    intervalDots

                    Spacer()

                    // Controls
                    controlButtons

                    Spacer().frame(height: 20)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        let color: Color = {
            guard let interval = timerManager.engine.currentInterval else { return .black }
            switch interval.type {
            case .work: return Color.orange.opacity(0.08)
            case .shortBreak: return Color.green.opacity(0.08)
            case .longBreak: return Color.blue.opacity(0.08)
            }
        }()

        return LinearGradient(
            colors: [color, .black],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.8), value: timerManager.engine.currentIntervalIndex)
    }

    // MARK: - Workflow Picker

    private var workflowPicker: some View {
        Menu {
            ForEach(timerManager.workflows) { workflow in
                Button(action: {
                    if timerManager.engine.state == .idle {
                        timerManager.selectWorkflow(workflow)
                    }
                }) {
                    HStack {
                        Text(workflow.name)
                        if workflow.id == timerManager.selectedWorkflow?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(timerManager.selectedWorkflow?.name ?? "Select Workflow")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .disabled(timerManager.engine.state != .idle)
    }

    // MARK: - Interval Label

    private var intervalLabel: some View {
        Text(timerManager.engine.currentInterval?.type.displayName ?? "Ready")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(intervalColor)
            .animation(.easeInOut, value: timerManager.engine.currentIntervalIndex)
    }

    // MARK: - Timer Circle

    private var timerCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                .frame(width: 260, height: 260)

            // Progress circle
            Circle()
                .trim(from: 0, to: timerManager.engine.progress)
                .stroke(
                    intervalColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerManager.engine.progress)

            // Inner content
            VStack(spacing: 4) {
                Text(timerManager.engine.formattedTime)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                if let workflow = timerManager.selectedWorkflow {
                    Text(workflow.formattedTotal + " total")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Time Display (overall progress)

    private var timeDisplay: some View {
        HStack(spacing: 24) {
            VStack(spacing: 2) {
                Text("\(timerManager.engine.elapsedFocusSeconds / 60)")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.medium)
                Text("Focus min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Rectangle()
                .frame(width: 1, height: 28)
                .foregroundStyle(.quaternary)

            VStack(spacing: 2) {
                Text("\(timerManager.engine.completedIntervalsCount)")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.medium)
                Text("Intervals")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Interval Progress Dots

    private var intervalDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(timerManager.engine.intervals.enumerated()), id: \.offset) { index, interval in
                Circle()
                    .fill(dotColor(for: index, interval: interval))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func dotColor(for index: Int, interval: TimerInterval) -> Color {
        if index < timerManager.engine.currentIntervalIndex {
            return intervalColor.opacity(0.6)
        } else if index == timerManager.engine.currentIntervalIndex {
            return intervalColor
        }
        return Color.gray.opacity(0.3)
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Reset
            Button(action: {
                if timerManager.engine.elapsedFocusSeconds > 30 {
                    timerManager.saveCompletedSession(context: viewContext)
                }
                timerManager.resetTimer()
                liveActivityManager.endActivity()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .opacity(timerManager.engine.state == .idle ? 0.4 : 1)
            .disabled(timerManager.engine.state == .idle)

            // Play/Pause (main button)
            Button(action: {
                switch timerManager.engine.state {
                case .idle:
                    timerManager.startTimer()
                    startLiveActivity()
                case .running:
                    timerManager.pauseTimer()
                case .paused:
                    timerManager.resumeTimer()
                case .completed:
                    timerManager.saveCompletedSession(context: viewContext)
                    timerManager.resetTimer()
                    liveActivityManager.endActivity()
                }
            }) {
                Image(systemName: mainButtonIcon)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(intervalColor, in: Circle())
                    .shadow(color: intervalColor.opacity(0.4), radius: 12, y: 4)
            }

            // Skip
            Button(action: {
                timerManager.skipInterval()
                updateLiveActivity()
            }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .opacity(timerManager.engine.state == .running || timerManager.engine.state == .paused ? 1 : 0.4)
            .disabled(timerManager.engine.state != .running && timerManager.engine.state != .paused)
        }
    }

    private var mainButtonIcon: String {
        switch timerManager.engine.state {
        case .idle: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        case .completed: return "checkmark"
        }
    }

    // MARK: - Colors

    private var intervalColor: Color {
        guard let interval = timerManager.engine.currentInterval else { return .orange }
        switch interval.type {
        case .work: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    // MARK: - Live Activity Helpers

    private func startLiveActivity() {
        guard let workflow = timerManager.selectedWorkflow,
              let interval = timerManager.engine.currentInterval else { return }

        liveActivityManager.startActivity(
            workflowName: workflow.name,
            workflowId: workflow.id,
            remainingSeconds: timerManager.engine.remainingSeconds,
            intervalType: interval.type.rawValue,
            intervalIndex: timerManager.engine.currentIntervalIndex,
            totalIntervals: timerManager.engine.intervals.count
        )
    }

    private func updateLiveActivity() {
        guard let workflow = timerManager.selectedWorkflow,
              let interval = timerManager.engine.currentInterval else { return }

        liveActivityManager.updateActivity(
            remainingSeconds: timerManager.engine.remainingSeconds,
            intervalType: interval.type.rawValue,
            workflowName: workflow.name,
            intervalIndex: timerManager.engine.currentIntervalIndex,
            totalIntervals: timerManager.engine.intervals.count
        )
    }
}
