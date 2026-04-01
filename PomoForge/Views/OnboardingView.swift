// OnboardingView.swift
// First-launch onboarding — explains the app and requests notification permission

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Welcome to PomoForge",
                    subtitle: "A distraction-free Pomodoro timer\nbuilt for deep focus.",
                    detail: nil
                )
                .tag(0)

                // Page 2: Workflows
                OnboardingPage(
                    icon: "list.bullet.rectangle",
                    iconColor: .blue,
                    title: "Custom Workflows",
                    subtitle: "Build your perfect focus routine.",
                    detail: "Create unlimited named workflows — set focus durations, break lengths, and repeat cycles exactly how you work best."
                )
                .tag(1)

                // Page 3: Stay on track
                OnboardingPage(
                    icon: "bell.badge.fill",
                    iconColor: .green,
                    title: "Stay on Track",
                    subtitle: "Get notified when intervals change.",
                    detail: "PomoForge sends gentle notifications so you know when to focus and when to rest — even when your phone is locked."
                )
                .tag(2)

                // Page 4: Get started
                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.yellow)

                    VStack(spacing: 12) {
                        Text("Track Your Progress")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("See your daily focus time, build streaks,\nand watch your productivity grow.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    Button(action: {
                        NotificationManager.shared.requestPermission()
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.orange, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)

                    // Page indicator
                    Text("Notifications will be requested to alert you between intervals.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer().frame(height: 20)
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let detail: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(iconColor)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                }
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}
