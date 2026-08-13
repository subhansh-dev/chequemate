// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Huewaves",
    platforms: [.iOS(.v26)],
    products: [
        .executable(name: "Huewaves", targets: ["Huewaves"])
    ],
    targets: [
        .executableTarget(
            name: "Huewaves",
            path: "Sources",
            cSettings: [
                .headerSearchPath("Audio/include")
            ]
        )
    ]
)
