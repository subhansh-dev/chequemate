// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Huewaves",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Huewaves", targets: ["Huewaves"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Huewaves",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources"
        )
    ]
)
