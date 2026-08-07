// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Synesthesia",
    platforms: [.iOS(.v26)],
    products: [
        .executableProduct(name: "Synesthesia", targets: ["Synesthesia"])
    ],
    targets: [
        .executableTarget(
            name: "Synesthesia",
            path: "Sources"
        )
    ]
)
