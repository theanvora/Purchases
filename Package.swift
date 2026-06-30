// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Purchases",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Purchases", targets: ["Purchases"]),
    ],
    targets: [
        .target(name: "Purchases"),
        .testTarget(name: "PurchasesTests", dependencies: ["Purchases"]),
    ]
)
