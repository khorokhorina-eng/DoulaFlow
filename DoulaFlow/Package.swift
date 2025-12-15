// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DoulaFlow",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DoulaFlowApp",
            targets: ["DoulaFlowApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift", from: "0.4.1"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "DoulaFlowApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                "SwiftSoup"
            ],
            path: "Sources",
            resources: [
                .process("DoulaFlowApp/Resources")
            ]
        ),
        .testTarget(
            name: "DoulaFlowAppTests",
            dependencies: ["DoulaFlowApp"],
            path: "Tests/DoulaFlowAppTests"
        )
    ]
)
