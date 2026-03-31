// PomoForgeWatchApp.swift
// Apple Watch app — simple timer companion

import SwiftUI

@main
struct PomoForgeWatchApp: App {
    @StateObject private var watchTimerManager = WatchTimerManager()

    var body: some Scene {
        WindowGroup {
            WatchTimerView()
                .environmentObject(watchTimerManager)
        }
    }
}
