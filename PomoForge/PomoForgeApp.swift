// PomoForgeApp.swift
// PomoForge — Distraction-free Pomodoro timer with infinite custom workflows

import SwiftUI
import CoreData

@main
struct PomoForgeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var timerManager = TimerManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedTheme") private var selectedTheme = "dark"

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(timerManager)
                    .environmentObject(subscriptionManager)
                    .preferredColorScheme(.dark)
                    .tint(themeAccentColor)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
    }

    private var themeAccentColor: Color {
        switch selectedTheme {
        case "midnight": return .indigo
        case "forest": return .green
        case "ocean": return .cyan
        default: return .orange
        }
    }
}
