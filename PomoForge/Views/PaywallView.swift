// PaywallView.swift
// RevenueCat paywall with placeholder offering
// Replace with RevenueCat's PaywallView or custom implementation after adding SDK

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly

    enum Plan {
        case monthly, yearly
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.orange.opacity(0.15), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.orange)

                            Text("PomoForge Pro")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Unlock your full focus potential")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)

                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "infinity", title: "Unlimited Workflows", subtitle: "Create as many custom workflows as you need")
                            FeatureRow(icon: "chart.bar.fill", title: "Full History & Charts", subtitle: "Weekly, monthly, and yearly focus analytics")
                            FeatureRow(icon: "square.and.arrow.up", title: "CSV Export", subtitle: "Export all your session data")
                            FeatureRow(icon: "applewatch", title: "Watch Complications", subtitle: "See your timer on Apple Watch")
                            FeatureRow(icon: "person.2.fill", title: "Family Sharing", subtitle: "Share your focus sessions with family")
                            FeatureRow(icon: "paintbrush.fill", title: "Themes & Sounds", subtitle: "Custom themes and timer sounds")
                        }
                        .padding(.horizontal)

                        // Plan selector
                        VStack(spacing: 12) {
                            PlanCard(
                                title: "Yearly",
                                price: "$24.99/year",
                                subtitle: "Save 30% — $2.08/mo",
                                isSelected: selectedPlan == .yearly,
                                badge: "BEST VALUE"
                            ) {
                                selectedPlan = .yearly
                            }

                            PlanCard(
                                title: "Monthly",
                                price: "$2.99/month",
                                subtitle: "Cancel anytime",
                                isSelected: selectedPlan == .monthly,
                                badge: nil
                            ) {
                                selectedPlan = .monthly
                            }
                        }
                        .padding(.horizontal)

                        // Subscribe button
                        Button(action: subscribe) {
                            Text("Start Free Trial")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.orange, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)

                        // Restore + terms
                        VStack(spacing: 8) {
                            Button("Restore Purchases") {
                                // await subscriptionManager.restorePurchases()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            Text("7-day free trial, then auto-renews. Cancel anytime.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func subscribe() {
        // Placeholder — replace with RevenueCat purchase call:
        // Task {
        //     try await selectedPlan == .monthly
        //         ? subscriptionManager.purchaseMonthly()
        //         : subscriptionManager.purchaseYearly()
        //     dismiss()
        // }
        print("RevenueCat: Purchase \(selectedPlan)")
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let title: String
    let price: String
    let subtitle: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.orange, in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RevenueCat PaywallView Integration
// After adding RevenueCat SDK 5.x via SPM, you can replace the custom PaywallView
// with RevenueCat's built-in PaywallView:
//
// import RevenueCatUI
//
// struct ProPaywallView: View {
//     var body: some View {
//         PaywallView()
//             .onPurchaseCompleted { customerInfo in
//                 // Handle successful purchase
//             }
//     }
// }
