import StoreKit

/// The result of attempting a purchase.
public enum PurchaseOutcome: Sendable {
    case success
    case pending
    case cancelled
}

/// The port a paywall / view model depends on, so UI code stays decoupled from
/// the concrete StoreKit `PurchaseManager` and can be driven by a stub in tests.
@MainActor
public protocol PurchaseServicing: AnyObject {
    var products: [Product] { get }
    var purchasedIDs: Set<String> { get }
    var isLoading: Bool { get }
    var hasActiveEntitlement: Bool { get }

    func load() async
    @discardableResult
    func purchase(_ product: Product) async throws -> PurchaseOutcome
    func restore() async throws
    func isPurchased(_ id: String) -> Bool
}

extension PurchaseManager: PurchaseServicing {}
