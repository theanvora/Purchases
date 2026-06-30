import Foundation
import StoreKit
import OSLog

private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Purchases", category: "purchase")

/// A StoreKit 2 facade: loads products, runs purchases, restores, and keeps a
/// live set of entitlements you can observe from SwiftUI.
@MainActor
public final class PurchaseManager: ObservableObject {
    /// Product identifiers configured in App Store Connect.
    @Published public private(set) var products: [Product] = []
    /// Product identifiers the user currently owns / is subscribed to.
    @Published public private(set) var purchasedIDs: Set<String> = []
    @Published public private(set) var isLoading = false

    private let productIDs: Set<String>
    private var updates: Task<Void, Never>?

    public init(productIDs: Set<String>) {
        self.productIDs = productIDs
        updates = listenForTransactions()
    }

    deinit { updates?.cancel() }

    public var hasActiveEntitlement: Bool { !purchasedIDs.isEmpty }

    public func isPurchased(_ id: String) -> Bool { purchasedIDs.contains(id) }

    /// Fetch products and refresh entitlements. Call once on launch / paywall appear.
    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            log.error("Failed to load products: \(error.localizedDescription)")
        }
        await refreshEntitlements()
    }

    public enum PurchaseOutcome: Sendable { case success, pending, cancelled }

    @discardableResult
    public func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    public func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    public func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedIDs = owned
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let safe):       return safe
        }
    }
}
