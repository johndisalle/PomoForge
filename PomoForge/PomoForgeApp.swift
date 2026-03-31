// PomoForgeApp.swift
// PomoForge — Distraction-free Pomodoro timer with infinite custom workflows
// Target: iOS 18.0+, SwiftUI, Xcode 16

import SwiftUI

@main
struct PomoForgeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var timerManager = TimerManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(timerManager)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.dark)
        }
    }
}
