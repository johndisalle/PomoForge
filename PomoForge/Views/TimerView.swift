// TimerView.swift
// Main countdown screen with themes, paywall triggers, rate prompt

import SwiftUI
import StoreKit
import CoreData

struct TimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.requestReview) private var requestReview

    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedTheme") private var selectedTheme = "dark"
    @AppStorage("totalCompletedSessions") private var totalCompletedSessions = 0
    @AppStorage("hasSeenFirstSessionPaywall") private var hasSeenFirstSessionPaywall = false
    @AppStorage("hasSeenThirdSessionPaywall") private var hasSeenThirdSessionPaywall = false
    @AppStorage("hasBeenAskedToRate") private var hasBeenAskedToRate = false

    @State private var showResetConfirmation = false
    @State private var showCelebration = false
    @State private var todayFocusMinutes = 0
    @State private var celebrationScale: CGFloat = 0.5
    @State private var celebrationOpacity: Double = 0
    @State private var showPaywall = false

    private var theme: AppThemeColors {
        AppThemeColors.forTheme(selectedTheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    HStack {
                        workflowPicker
                        Spacer()
                        todayBadge
                    }
                    Spacer()
                    intervalLabel
                    timerCircle
                    nextUpLabel
                    timeDisplay
                    intervalDots
                    Spacer()
                    controlButtons
                    Spacer().frame(height: 20)
                }
                .padding()

                if showCelebration {
                    celebrationOverlay
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background && timerManager.engine.state == .running {
                    if let interval = timerManager.engine.currentInterval {
                        WidgetManager.shared.updateCurrentSession(
                            isActive: true,
                            intervalType: interval.type.rawValue,
                            remainingSeconds: timerManager.engine.remainingSeconds,
                            workflowName: timerManager.selectedWorkflow?.name ?? "",
                            endDate: Date().addingTimeInterval(TimeInterval(timerManager.engine.remainingSeconds))
                        )
                    }
                    updateLiveActivity()
                }
                if newPhase == .inactive && timerManager.engine.state != .running {
                    WidgetManager.shared.clearCurrentSession()
                }
            }
            .onChange(of: timerManager.engine.state) { _, newState in
                if newState == .completed {
                    handleSessionComplete()
                }
            }
        }
    }

    // MARK: - Session Complete (paywall triggers, rate prompt, streak)

    private func handleSessionComplete() {
        totalCompletedSessions += 1
        timerManager.saveCompletedSession(context: viewContext)

        // Cancel streak reminder since they completed a session today
        NotificationManager.shared.cancelStreakReminder()
        loadTodayFocus()

        // Show celebration
        showCelebrationAnimation()

        // Schedule streak reminder for tomorrow
        let streak = calculateCurrentStreak()
        if streak > 0 {
            NotificationManager.shared.scheduleStreakReminder(currentStreak: streak)
        }
    }

    private func dismissCelebration() {
        timerManager.resetTimer()
        WidgetManager.shared.clearCurrentSession()
        liveActivityManager.endActivity()

        withAnimation(.easeOut(duration: 0.2)) {
            celebrationOpacity = 0
            celebrationScale = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showCelebration = false
            celebrationScale = 0.5

            // Strategic paywall & rate triggers (after celebration dismisses)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                triggerPostSessionActions()
            }
        }
    }

    private func triggerPostSessionActions() {
        // Don't show anything to Pro users except rate prompt
        if subscriptionManager.tier == .free {
            // After 1st session
            if totalCompletedSessions == 1 && !hasSeenFirstSessionPaywall {
                hasSeenFirstSessionPaywall = true
                showPaywall = true
                return
            }
            // After 3rd session
            if totalCompletedSessions == 3 && !hasSeenThirdSessionPaywall {
                hasSeenThirdSessionPaywall = true
                showPaywall = true
                return
            }
        }

        // Rate prompt: after 3rd or 5th completed session
        if !hasBeenAskedToRate && (totalCompletedSessions == 3 || totalCompletedSessions == 5) {
            hasBeenAskedToRate = true
            requestReview()
        }
    }

    private func calculateCurrentStreak() -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDSession")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]

        guard let results = try? viewContext.fetch(request) else { return 0 }
        let sessions = results.compactMap { ($0 as AnyObject).value(forKey: "startedAt") as? Date }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let daySet = Set(sessions.map { calendar.startOfDay(for: $0) })

        while daySet.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    // MARK: - Celebration Overlay

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { dismissCelebration() }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.bounce, value: showCelebration)

                Text("Workflow Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text(timerManager.selectedWorkflow?.name ?? "")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(timerManager.engine.elapsedFocusSeconds / 60)")
                            .font(.title2.bold())
                        Text("Focus min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 4) {
                        Text("\(timerManager.engine.completedIntervalsCount)")
                            .font(.title2.bold())
                        Text("Intervals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                // Streak badge
                let streak = calculateCurrentStreak()
                if streak > 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Text("\(streak)-day streak!")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.15), in: Capsule())
                }

                Button(action: { dismissCelebration() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(theme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 12)
            }
            .scaleEffect(celebrationScale)
            .opacity(celebrationOpacity)
        }
    }

    private func showCelebrationAnimation() {
        showCelebration = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            celebrationScale = 1.0
            celebrationOpacity = 1.0
        }
    }

    // MARK: - Background (themed)

    private var backgroundGradient: some View {
        let color: Color = {
            guard let interval = timerManager.engine.currentInterval,
                  timerManager.engine.state != .idle else { return .clear }
            return theme.gradientForInterval(interval.type)
        }()

        return LinearGradient(
            colors: [color, theme.background],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.8), value: timerManager.engine.currentIntervalIndex)
    }

    // MARK: - Today Badge

    private var todayBadge: some View {
        let totalMinutes = todayFocusMinutes + (timerManager.engine.elapsedFocusSeconds / 60)
        return HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
            Text("\(totalMinutes)m today")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear { loadTodayFocus() }
    }

    private func loadTodayFocus() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDSession")
        let today = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "startedAt >= %@", today as NSDate)

        if let results = try? viewContext.fetch(request) {
            todayFocusMinutes = results.reduce(0) { total, obj in
                total + Int((obj as AnyObject).value(forKey: "totalFocusSeconds") as? Int32 ?? 0)
            } / 60
        }
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

    // MARK: - Timer Circle (themed)

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                .frame(width: 260, height: 260)

            Circle()
                .trim(from: 0, to: timerManager.engine.progress)
                .stroke(
                    intervalColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerManager.engine.progress)

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

    // MARK: - Next Up Label

    private var nextUpLabel: some View {
        Group {
            if timerManager.engine.state == .running || timerManager.engine.state == .paused,
               let nextLabel = timerManager.nextIntervalLabel {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text(nextLabel)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.opacity.combined(with: .scale))
            } else if timerManager.engine.state == .idle {
                Text("Tap play to start focusing")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .animation(.easeInOut, value: timerManager.engine.currentIntervalIndex)
    }

    // MARK: - Time Display

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

    // MARK: - Interval Dots

    private var intervalDots: some View {
        HStack(spacing: 6) {
            ForEach(Array(timerManager.engine.intervals.enumerated()), id: \.offset) { index, interval in
                Circle()
                    .fill(dotColor(for: index, interval: interval))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == timerManager.engine.currentIntervalIndex && timerManager.engine.state == .running ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                               value: timerManager.engine.state == .running && index == timerManager.engine.currentIntervalIndex)
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
                if timerManager.engine.elapsedFocusSeconds > 60 {
                    showResetConfirmation = true
                } else {
                    timerManager.resetTimer()
                    liveActivityManager.endActivity()
                    WidgetManager.shared.clearCurrentSession()
                }
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .opacity(timerManager.engine.state == .idle ? 0.4 : 1)
            .disabled(timerManager.engine.state == .idle)
            .alert("Reset Timer?", isPresented: $showResetConfirmation) {
                Button("Save & Reset", role: .destructive) {
                    timerManager.saveCompletedSession(context: viewContext)
                    timerManager.resetTimer()
                    liveActivityManager.endActivity()
                    WidgetManager.shared.clearCurrentSession()
                }
                Button("Discard & Reset", role: .destructive) {
                    timerManager.resetTimer()
                    liveActivityManager.endActivity()
                    WidgetManager.shared.clearCurrentSession()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have \(timerManager.engine.elapsedFocusSeconds / 60) minutes of focus time. Save this session?")
            }

            // Play/Pause
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
                    break
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

    // MARK: - Colors (themed)

    private var intervalColor: Color {
        guard let interval = timerManager.engine.currentInterval else { return theme.accent }
        switch interval.type {
        case .work: return theme.accent
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard let workflow = timerManager.selectedWorkflow,
              let interval = timerManager.engine.currentInterval else { return }
        liveActivityManager.startActivity(
            workflowName: workflow.name, workflowId: workflow.id,
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
            intervalType: interval.type.rawValue, workflowName: workflow.name,
            intervalIndex: timerManager.engine.currentIntervalIndex,
            totalIntervals: timerManager.engine.intervals.count
        )
    }
}
