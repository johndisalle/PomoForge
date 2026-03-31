# PomoForge — Xcode Project Setup

## Step-by-Step: Create the Project in Xcode 16

### 1. Create the iOS App

1. Open Xcode 16 → **File → New → Project**
2. Select **iOS → App**
3. Settings:
   - **Product Name:** `PomoForge`
   - **Team:** Your Apple Developer team
   - **Organization Identifier:** `com.pomoforge`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** Core Data
   - **Minimum Deployment:** iOS 18.0
4. Click **Create**, save to the cloned repo directory
5. Delete the auto-generated `ContentView.swift` and Core Data files — we have our own

### 2. Add Source Files

1. In Xcode's Project Navigator, right-click the `PomoForge` group
2. **Add Files to "PomoForge"** → select all files from:
   - `PomoForge/PomoForgeApp.swift`
   - `PomoForge/Persistence.swift`
   - `PomoForge/Models/` (all .swift files)
   - `PomoForge/Views/` (all .swift files)
   - `PomoForge/Services/` (all .swift files)
3. Make sure "Copy items if needed" is **unchecked** (files are already in place)
4. Replace the auto-generated `.xcdatamodeld` with `PomoForge/PomoForge.xcdatamodeld`

### 3. Add the Widget Extension

1. **File → New → Target**
2. Select **iOS → Widget Extension**
3. Settings:
   - **Product Name:** `PomoForgeWidget`
   - **Include Live Activity:** YES
   - **Include Configuration App Intent:** NO
4. Delete auto-generated widget files
5. Add files from `PomoForgeWidget/`:
   - `PomoForgeWidget.swift`
   - `LiveActivityView.swift`
6. In the widget target's **Build Settings**, set Deployment Target to **iOS 18.0**

### 4. Add the Watch App

1. **File → New → Target**
2. Select **watchOS → App**
3. Settings:
   - **Product Name:** `PomoForgeWatch`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Watch Connectivity:** YES (optional, for phone↔watch sync)
4. Delete auto-generated files
5. Add files from `PomoForgeWatch/`:
   - `PomoForgeWatchApp.swift`
   - `Views/WatchTimerView.swift`
   - `Services/WatchTimerManager.swift`
   - `Complications/ComplicationViews.swift`
6. Set watchOS Deployment Target to **11.0**

### 5. Configure Capabilities

For the **PomoForge** (iOS) target:
1. Go to **Signing & Capabilities**
2. Add these capabilities:
   - **iCloud** → Enable CloudKit, container: `iCloud.com.pomoforge.app`
   - **App Groups** → Add: `group.com.pomoforge.shared`
   - **Background Modes** → Enable: Audio, Background fetch
   - **Push Notifications** (required for Live Activities)

For the **PomoForgeWidget** target:
1. Add **App Groups** → `group.com.pomoforge.shared`

### 6. Add RevenueCat SDK

1. **File → Add Package Dependencies**
2. Search: `https://github.com/RevenueCat/purchases-ios`
3. Select version rule: **Up to Next Major (5.0.0)**
4. Add `RevenueCat` and `RevenueCatUI` to the PomoForge iOS target
5. In `SubscriptionManager.swift`:
   - Uncomment `import RevenueCat`
   - Uncomment all the RevenueCat methods
   - Replace `YOUR_REVENUECAT_API_KEY` with your actual API key
6. In `PaywallView.swift`:
   - Optionally replace with RevenueCat's built-in `PaywallView` from `RevenueCatUI`

### 7. Add Timer Sound Files

Place these audio files in `PomoForge/Resources/`:
- `bell.wav` (or .mp3/.m4a)
- `chime.wav`
- `crystal.wav`
- `pulse.wav`

You can use any short (1-3 second) notification sounds. Free options:
- [freesound.org](https://freesound.org) — search "bell notification"
- Record custom sounds using GarageBand

Make sure to add them to the iOS target in Xcode (Build Phases → Copy Bundle Resources).

### 8. App Icon

1. Create a 1024x1024 app icon (flame/forge theme, orange on dark background)
2. Drop it into `Assets.xcassets/AppIcon.appiconset/`
3. Update `Contents.json` with the filename

### 9. Build & Run

1. Select an iPhone simulator (iOS 18.0+)
2. **Product → Build** (⌘B)
3. **Product → Run** (⌘R)

## Project File Tree

```
PomoForge/
├── SETUP.md
├── Package.swift                          # SPM for RevenueCat
├── PomoForge/
│   ├── PomoForgeApp.swift                 # @main App entry point
│   ├── Persistence.swift                  # Core Data + CloudKit stack
│   ├── Info.plist                         # Live Activities, orientation
│   ├── PomoForge.xcdatamodeld/            # Core Data model
│   │   └── PomoForge.xcdatamodel/
│   │       └── contents                   # CDWorkflow, CDSession, CDFocusSessionShare
│   ├── Models/
│   │   ├── Workflow.swift                 # Workflow domain model + intervals
│   │   ├── Session.swift                  # FocusSession model + CSV export
│   │   └── TimerEngine.swift              # Pure timer state machine
│   ├── Views/
│   │   ├── ContentView.swift              # Tab bar (Timer/Workflows/History/Settings)
│   │   ├── TimerView.swift                # Main countdown with circular progress
│   │   ├── WorkflowBuilderView.swift      # Create/edit workflows, drag reorder
│   │   ├── HistoryView.swift              # Charts, streak, session list
│   │   ├── SettingsView.swift             # Sounds, themes, CloudKit toggle
│   │   └── PaywallView.swift              # RevenueCat paywall (placeholder)
│   ├── Services/
│   │   ├── TimerManager.swift             # Central orchestrator (timer, haptics, sounds)
│   │   ├── LiveActivityManager.swift      # ActivityKit Live Activities
│   │   ├── WidgetManager.swift            # App Groups shared data for widgets
│   │   └── SubscriptionManager.swift      # RevenueCat freemium logic
│   ├── Resources/                         # Timer sounds (add manually)
│   └── Assets.xcassets/                   # App icon, accent color
├── PomoForgeWidget/
│   ├── PomoForgeWidget.swift              # Current Session + Today's Focus widgets
│   └── LiveActivityView.swift             # Lock Screen + Dynamic Island UI
└── PomoForgeWatch/
    ├── PomoForgeWatchApp.swift            # Watch @main entry
    ├── Views/
    │   └── WatchTimerView.swift           # Watch timer UI
    ├── Services/
    │   └── WatchTimerManager.swift        # Standalone watch timer
    └── Complications/
        └── ComplicationViews.swift        # Circular/rectangular complications
```

## RevenueCat Integration Code

### Full integration snippet (paste into SubscriptionManager.swift after adding SDK):

```swift
import RevenueCat

// In init():
func configureRevenueCat() {
    Purchases.logLevel = .debug
    Purchases.configure(withAPIKey: "your_api_key_here")
}

// Check status on app launch:
func checkSubscriptionStatus() {
    isLoading = true
    Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
        Task { @MainActor in
            self?.isLoading = false
            if customerInfo?.entitlements["pro"]?.isActive == true {
                self?.tier = .pro
            } else {
                self?.tier = .free
            }
        }
    }
}

// Purchase monthly:
func purchaseMonthly() async throws {
    let offerings = try await Purchases.shared.offerings()
    guard let package = offerings.current?.monthly else {
        throw SubscriptionError.noOffering
    }
    let result = try await Purchases.shared.purchase(package: package)
    if result.customerInfo.entitlements["pro"]?.isActive == true {
        tier = .pro
    }
}

// Purchase yearly:
func purchaseYearly() async throws {
    let offerings = try await Purchases.shared.offerings()
    guard let package = offerings.current?.annual else {
        throw SubscriptionError.noOffering
    }
    let result = try await Purchases.shared.purchase(package: package)
    if result.customerInfo.entitlements["pro"]?.isActive == true {
        tier = .pro
    }
}

// Restore:
func restorePurchases() async throws {
    let customerInfo = try await Purchases.shared.restorePurchases()
    if customerInfo.entitlements["pro"]?.isActive == true {
        tier = .pro
    }
}
```

### RevenueCat Dashboard Setup:
1. Create app at [app.revenuecat.com](https://app.revenuecat.com)
2. Create products:
   - `com.pomoforge.pro.monthly` — $2.99/month
   - `com.pomoforge.pro.yearly` — $24.99/year (save 30%)
3. Create entitlement: `pro`
4. Create offering: `default` with both products
5. Copy your API key into `SubscriptionManager.apiKey`

### Using RevenueCat's Built-in PaywallView:

```swift
import RevenueCatUI

struct ProPaywallView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { customerInfo in
                if customerInfo.entitlements["pro"]?.isActive == true {
                    SubscriptionManager.shared.tier = .pro
                }
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                if customerInfo.entitlements["pro"]?.isActive == true {
                    SubscriptionManager.shared.tier = .pro
                }
                dismiss()
            }
    }
}
```
