// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DoulaFlow",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "DoulaFlow",
            targets: ["DoulaFlowApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.40.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
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
