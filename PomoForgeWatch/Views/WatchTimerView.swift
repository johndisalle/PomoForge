// WatchTimerView.swift
// Watch app main timer view with complications support

import SwiftUI

struct WatchTimerView: View {
    @EnvironmentObject var timerManager: WatchTimerManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Interval type
                Text(timerManager.currentIntervalLabel)
                    .font(.caption2)
                    .foregroundStyle(timerManager.intervalColor)
                    .fontWeight(.semibold)

                // Timer circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(
                            timerManager.intervalColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerManager.progress)

                    VStack(spacing: 2) {
                        Text(timerManager.formattedTime)
                            .font(.system(size: 32, weight: .thin, design: .rounded))
                            .monospacedDigit()

                        Text(timerManager.workflowName)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: 140, height: 140)

                // Controls
                HStack(spacing: 20) {
                    Button(action: timerManager.reset) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .disabled(!timerManager.isActive)

                    Button(action: {
                        if timerManager.isRunning {
                            timerManager.pause()
                        } else {
                            timerManager.start()
                        }
                    }) {
                        Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                            .font(.title3)
                    }
                    .tint(timerManager.intervalColor)

                    Button(action: timerManager.skip) {
                        Image(systemName: "forward.fill")
                    }
                    .disabled(!timerManager.isActive)
                }
            }
            .navigationTitle("PomoForge")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
