// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Huewaves",
    platforms: [.iOS(.v26)],
    products: [
        .executableProduct(name: "Huewaves", targets: ["Huewaves"])
    ],
    targets: [
        .executableTarget(
            name: "Huewaves",
            path: "Sources"
        )
    ]
)
