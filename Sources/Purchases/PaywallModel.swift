import StoreKit
import Observation

/// A ready-made `@Observable` view model for a paywall. It depends on the
/// `PurchaseServicing` port (not the concrete manager), so it's easy to preview
/// and unit-test with a stub.
///
/// ```swift
/// @State private var model = PaywallModel(purchases: purchaseManager)
/// // .task { await model.load() } ; Button { Task { await model.buy(product) } }
/// ```
@MainActor
@Observable
public final class PaywallModel {
    public private(set) var products: [Product] = []
    public private(set) var isLoading = false
    public private(set) var isPurchasing = false
    public private(set) var errorMessage: String?
    public var selectedProduct: Product?

    public var isSubscribed: Bool { purchases.hasActiveEntitlement }

    @ObservationIgnored private let purchases: PurchaseServicing

    public init(purchases: PurchaseServicing) {
        self.purchases = purchases
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        await purchases.load()
        products = purchases.products
        if selectedProduct == nil { selectedProduct = products.first }
    }

    /// Purchase a product (defaults to the selected one). Returns `true` on success.
    @discardableResult
    public func buy(_ product: Product? = nil) async -> Bool {
        guard let product = product ?? selectedProduct else { return false }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            return try await purchases.purchase(product) == .success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func restore() async {
        errorMessage = nil
        do {
            try await purchases.restore()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
