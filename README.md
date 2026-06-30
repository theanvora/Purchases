# Purchases

A StoreKit 2 facade for in-app purchases and subscriptions — load products, purchase, restore, and observe entitlements from SwiftUI. No third-party SDK.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/iOS-16%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

## Features

- **`PurchaseManager`** — an `ObservableObject` you bind to a paywall.
- Product loading, purchase, and `AppStore.sync()` restore.
- Live **entitlements** via `Transaction.currentEntitlements` and a background `Transaction.updates` listener.
- Verified transactions only (`VerificationResult` checked).

## Installation

```swift
.package(url: "https://github.com/theanvora/Purchases.git", from: "1.0.0")
```

## Usage

```swift
import Purchases

@State private var purchases = PurchaseManager(productIDs: ["com.app.pro.yearly"])

// On appear
.task { await purchases.load() }

// Buy
try await purchases.purchase(product)

// Gate features
if purchases.hasActiveEntitlement { unlockPro() }

// Restore
try await purchases.restore()
```

## Requirements

- iOS 17.0+ · Swift 5.9+ (uses the Observation framework)

## License

MIT
