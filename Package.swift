// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AinkradAppKit",
    platforms: [.macOS(.v14)],
    products: [
        // DYNAMIC: host embeds one copy; plugins resolve it at runtime. A static
        // product would duplicate protocol type metadata and break dynamic casts.
        .library(name: "AinkradAppKit", type: .dynamic, targets: ["AinkradAppKit"]),
    ],
    targets: [
        .target(name: "AinkradAppKit"),
        .testTarget(name: "AinkradAppKitTests", dependencies: ["AinkradAppKit"]),
    ]
)
