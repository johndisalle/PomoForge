// SubscriptionManager.swift
// RevenueCat integration for freemium subscription management
// Add RevenueCat Purchases SDK 5.x via SPM before uncommenting

import SwiftUI
// import RevenueCat

// MARK: - Subscription Tier

enum SubscriptionTier {
    case free
    case pro

    var maxWorkflows: Int {
        switch self {
        case .free: return 1
        case .pro: return .max
        }
    }

    var canExportCSV: Bool { self == .pro }
    var canAccessCharts: Bool { self == .pro }
    var canCustomizeSounds: Bool { self == .pro }
    var canUseThemes: Bool { self == .pro }
    var canUseFamilySharing: Bool { self == .pro }
    var canUseWatchComplications: Bool { self == .pro }
}

// MARK: - Subscription Manager

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var tier: SubscriptionTier = .free
    @Published var isLoading = false

    // RevenueCat constants — replace with your actual IDs
    static let apiKey = "YOUR_REVENUECAT_API_KEY"
    static let monthlyProductId = "com.pomoforge.pro.monthly"    // $2.99/mo
    static let yearlyProductId = "com.pomoforge.pro.yearly"      // $24.99/yr
    static let entitlementId = "pro"

    init() {
        // configureRevenueCat()
        // checkSubscriptionStatus()
    }

    // MARK: - RevenueCat Configuration
    // Uncomment after adding RevenueCat SDK via SPM

    /*
    func configureRevenueCat() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.apiKey)
    }

    func checkSubscriptionStatus() {
        isLoading = true
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                if let entitlement = customerInfo?.entitlements[Self.entitlementId],
                   entitlement.isActive {
                    self.tier = .pro
                } else {
                    self.tier = .free
                }
            }
        }
    }

    func purchaseMonthly() async throws {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.monthly else {
            throw SubscriptionError.noOffering
        }
        let result = try await Purchases.shared.purchase(package: package)
        if result.customerInfo.entitlements[Self.entitlementId]?.isActive == true {
            tier = .pro
        }
    }

    func purchaseYearly() async throws {
        let offerings = try await Purchases.shared.offerings()
        guard let package = offerings.current?.annual else {
            throw SubscriptionError.noOffering
        }
        let result = try await Purchases.shared.purchase(package: package)
        if result.customerInfo.entitlements[Self.entitlementId]?.isActive == true {
            tier = .pro
        }
    }

    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        if customerInfo.entitlements[Self.entitlementId]?.isActive == true {
            tier = .pro
        }
    }
    */

    // MARK: - Placeholder methods (work without RevenueCat)

    func checkSubscriptionStatus() {
        // Placeholder: defaults to free tier
        // Replace with RevenueCat implementation above
        tier = .free
    }

    func canCreateWorkflow(currentCount: Int) -> Bool {
        if tier == .pro { return true }
        return currentCount < 1 // Free tier: 1 saved workflow (default)
    }
}

enum SubscriptionError: LocalizedError {
    case noOffering

    var errorDescription: String? {
        switch self {
        case .noOffering: return "No subscription offering available."
        }
    }
}
