// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Huewaves",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Huewaves", targets: ["Huewaves"])
    ],
    targets: [
        .target(
            name: "Huewaves",
            path: "Sources"
        )
    ]
)
