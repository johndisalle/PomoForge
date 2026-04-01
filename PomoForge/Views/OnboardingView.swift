// OnboardingView.swift
// First-launch onboarding with soft paywall on final page

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var currentPage = 0
    @State private var isPurchasing = false
    @State private var errorMessage: String?

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
                    detail: "Create named workflows with custom focus and break durations — exactly how you work best."
                )
                .tag(1)

                // Page 3: Stay on track
                OnboardingPage(
                    icon: "bell.badge.fill",
                    iconColor: .green,
                    title: "Never Miss a Beat",
                    subtitle: "Smart notifications keep you in flow.",
                    detail: "Get gentle alerts when it's time to focus, break, or celebrate — even when your phone is locked."
                )
                .tag(2)

                // Page 4: Track progress
                OnboardingPage(
                    icon: "chart.bar.fill",
                    iconColor: .yellow,
                    title: "Watch Yourself Grow",
                    subtitle: "Track streaks, focus time, and more.",
                    detail: "Daily charts, streak counters, and session history so you can see your productivity compound over time."
                )
                .tag(3)

                // Page 5: Soft Paywall
                onboardingPaywall
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Onboarding Paywall (Page 5)

    private var onboardingPaywall: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                }

                Text("Unlock Your\nFull Potential")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Try PomoForge Pro free for 3 days")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 28)

            // Feature list
            VStack(alignment: .leading, spacing: 14) {
                OnboardingFeature(icon: "infinity", text: "Unlimited custom workflows")
                OnboardingFeature(icon: "chart.bar.fill", text: "Full history & analytics")
                OnboardingFeature(icon: "paintbrush.fill", text: "Premium themes & sounds")
                OnboardingFeature(icon: "square.and.arrow.up", text: "CSV export")
                OnboardingFeature(icon: "person.2.fill", text: "Family focus sharing")
            }
            .padding(.horizontal, 40)

            Spacer()

            // Pricing
            VStack(spacing: 16) {
                // Annual (best value)
                Button(action: { startPurchase(yearly: true) }) {
                    VStack(spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Annual")
                                        .font(.headline)
                                    Text("SAVE 30%")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(.orange, in: Capsule())
                                }
                                Text("3 days free, then $24.99/year")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("$2.08/mo")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                // Monthly
                Button(action: { startPurchase(yearly: false) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monthly")
                                .font(.headline)
                            Text("3 days free, then $2.99/month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("$2.99/mo")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            // CTA or loading
            if isPurchasing {
                ProgressView()
                    .tint(.orange)
                    .padding()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            // Skip / Restore
            VStack(spacing: 10) {
                Button(action: skipPaywall) {
                    Text("Continue with Free Plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: {
                    Task {
                        try? await subscriptionManager.restorePurchases()
                        if subscriptionManager.tier == .pro {
                            completeOnboarding()
                        }
                    }
                }) {
                    Text("Restore Purchases")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text("Cancel anytime. No commitment.")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .padding(.top, 4)
            }

            Spacer().frame(height: 24)
        }
    }

    // MARK: - Actions

    private func startPurchase(yearly: Bool) {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                if yearly {
                    try await subscriptionManager.purchaseYearly()
                } else {
                    try await subscriptionManager.purchaseMonthly()
                }
                completeOnboarding()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }

    private func skipPaywall() {
        completeOnboarding()
    }

    private func completeOnboarding() {
        NotificationManager.shared.requestPermission()
        withAnimation(.easeOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Feature Row

struct OnboardingFeature: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Onboarding Page

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
