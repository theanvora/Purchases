import XCTest
import StoreKit
@testable import Purchases

@MainActor
private final class StubPurchases: PurchaseServicing {
    var products: [Product] = []
    var purchasedIDs: Set<String> = []
    var isLoading = false
    var hasActiveEntitlement = false
    var loadCalled = false

    func load() async { loadCalled = true }
    func purchase(_ product: Product) async throws -> PurchaseOutcome { .cancelled }
    func restore() async throws {}
    func isPurchased(_ id: String) -> Bool { purchasedIDs.contains(id) }
}

@MainActor
final class PaywallModelTests: XCTestCase {
    func testReflectsEntitlement() {
        let stub = StubPurchases()
        stub.hasActiveEntitlement = true
        let model = PaywallModel(purchases: stub)
        XCTAssertTrue(model.isSubscribed)
    }

    func testLoadForwardsToService() async {
        let stub = StubPurchases()
        let model = PaywallModel(purchases: stub)
        await model.load()
        XCTAssertTrue(stub.loadCalled)
        XCTAssertTrue(model.products.isEmpty)
    }
}
