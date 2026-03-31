// SettingsView.swift
// Sound picker, themes, CloudKit toggle, subscription management

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @AppStorage("selectedSound") private var selectedSound = "bell"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("cloudKitSyncEnabled") private var cloudKitSyncEnabled = false
    @AppStorage("selectedTheme") private var selectedTheme = "dark"
    @AppStorage("showFamilySharing") private var showFamilySharing = false

    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                // Subscription
                subscriptionSection

                // Timer sounds
                soundsSection

                // Haptics
                hapticsSection

                // Appearance
                appearanceSection

                // CloudKit / Family Sharing
                cloudKitSection

                // About
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(subscriptionManager.tier == .pro ? "Pro" : "Free")
                            .font(.headline)
                        if subscriptionManager.tier == .pro {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                    Text(subscriptionManager.tier == .pro
                         ? "All features unlocked"
                         : "1 workflow, basic timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if subscriptionManager.tier == .free {
                    Button("Upgrade") { showingPaywall = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.small)
                }
            }
        } header: {
            Text("Subscription")
        }
    }

    // MARK: - Sounds Section

    private var soundsSection: some View {
        Section {
            ForEach(TimerSound.allCases) { sound in
                Button(action: {
                    if sound.requiresPro && subscriptionManager.tier != .pro {
                        showingPaywall = true
                    } else {
                        selectedSound = sound.id
                        timerManager.playSound(sound.id)
                    }
                }) {
                    HStack {
                        Image(systemName: sound.icon)
                            .foregroundStyle(sound.requiresPro && subscriptionManager.tier != .pro ? Color.gray : Color.orange)
                            .frame(width: 24)
                        Text(sound.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedSound == sound.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                        if sound.requiresPro && subscriptionManager.tier != .pro {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
        } header: {
            Text("Timer Sound")
        }
    }

    // MARK: - Haptics Section

    private var hapticsSection: some View {
        Section {
            Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                .tint(.orange)
        } header: {
            Text("Feedback")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            ForEach(AppTheme.allCases) { theme in
                Button(action: {
                    if theme.requiresPro && subscriptionManager.tier != .pro {
                        showingPaywall = true
                    } else {
                        selectedTheme = theme.id
                    }
                }) {
                    HStack {
                        Circle()
                            .fill(theme.previewColor)
                            .frame(width: 20, height: 20)
                        Text(theme.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedTheme == theme.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                        if theme.requiresPro && subscriptionManager.tier != .pro {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
        } header: {
            Text("Theme")
        }
    }

    // MARK: - CloudKit Section

    private var cloudKitSection: some View {
        Section {
            Toggle("iCloud Sync", isOn: $cloudKitSyncEnabled)
                .tint(.orange)

            if subscriptionManager.tier == .pro {
                Toggle("Family Focus Sharing", isOn: $showFamilySharing)
                    .tint(.orange)

                if showFamilySharing {
                    Text("Family members can see your active focus sessions in real time via CloudKit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button(action: { showingPaywall = true }) {
                    HStack {
                        Text("Family Focus Sharing")
                        Spacer()
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                }
                .foregroundStyle(.primary)
            }
        } header: {
            Text("Cloud & Sharing")
        } footer: {
            Text("iCloud sync keeps your workflows and history across devices. Family sharing lets others see when you're focusing.")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            // Placeholder for restore purchases
            Button("Restore Purchases") {
                // await subscriptionManager.restorePurchases()
            }
            .foregroundStyle(.orange)
        } header: {
            Text("About")
        }
    }
}

// MARK: - Timer Sound Options

enum TimerSound: String, CaseIterable, Identifiable {
    case bell
    case chime
    case crystal
    case pulse

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bell: return "Bell"
        case .chime: return "Chime"
        case .crystal: return "Crystal"
        case .pulse: return "Pulse"
        }
    }

    var icon: String {
        switch self {
        case .bell: return "bell.fill"
        case .chime: return "music.note"
        case .crystal: return "sparkles"
        case .pulse: return "waveform"
        }
    }

    var requiresPro: Bool {
        switch self {
        case .bell: return false
        case .chime, .crystal, .pulse: return true
        }
    }
}

// MARK: - App Themes

enum AppTheme: String, CaseIterable, Identifiable {
    case dark
    case midnight
    case forest
    case ocean

    var id: String { rawValue }

    var name: String {
        switch self {
        case .dark: return "Dark"
        case .midnight: return "Midnight"
        case .forest: return "Forest"
        case .ocean: return "Ocean"
        }
    }

    var previewColor: Color {
        switch self {
        case .dark: return .gray
        case .midnight: return .indigo
        case .forest: return .green
        case .ocean: return .blue
        }
    }

    var requiresPro: Bool {
        self != .dark
    }
}
