// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "ChequeMate",
    platforms: [.iOS(.v26)],
    products: [
        .executable(name: "ChequeMate", targets: ["ChequeMate"])
    ],
    targets: [
        .executableTarget(
            name: "ChequeMate",
            path: "Sources"
        )
    ]
)
