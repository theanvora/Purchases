import Foundation
import StoreKit

public extension Product {
    /// `true` for auto-renewable or non-renewing subscription products.
    var isSubscription: Bool { subscription != nil }

    /// Localized subscription period, e.g. "1 month", "1 year".
    var subscriptionPeriodText: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        let unit: String
        switch period.unit {
        case .day:   unit = "day"
        case .week:  unit = "week"
        case .month: unit = "month"
        case .year:  unit = "year"
        @unknown default: unit = "period"
        }
        return period.value == 1 ? "1 \(unit)" : "\(period.value) \(unit)s"
    }
}

public extension PurchaseManager {
    /// The current renewal state for a subscription product, if any.
    func renewalState(for product: Product) async -> Product.SubscriptionInfo.RenewalState? {
        guard let statuses = try? await product.subscription?.status else { return nil }
        // Prefer a verified status; fall back to the first available.
        for status in statuses {
            if case .verified = status.transaction { return status.state }
        }
        return statuses.first?.state
    }

    /// Whether the user is eligible for an introductory offer / free trial.
    func isEligibleForIntroOffer(_ product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    /// Expiration date of the active subscription for `product`, if known.
    func expirationDate(for product: Product) async -> Date? {
        guard let statuses = try? await product.subscription?.status else { return nil }
        for status in statuses {
            guard case .verified(let renewal) = status.renewalInfo,
                  case .verified(let transaction) = status.transaction else { continue }
            if renewal.willAutoRenew || transaction.revocationDate == nil {
                return transaction.expirationDate
            }
        }
        return nil
    }
}
