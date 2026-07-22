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
        .target(
            name: "AinkradAppKit",
            swiftSettings: [
                // Resilient ABI: additive public changes no longer break already-compiled
                // plugin bundles that reuse the host's embedded copy. See SDK Generation
                // Contract design. Revision-pinned/branch dependents (host + plugins) are
                // unaffected by the unsafeFlags version-pin restriction.
                .unsafeFlags([
                    "-enable-library-evolution",
                    "-emit-module-interface",
                ])
            ]
        ),
        .testTarget(name: "AinkradAppKitTests", dependencies: ["AinkradAppKit"]),
    ]
)
