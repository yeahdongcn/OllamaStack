// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "performance-statistics",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "collector", targets: ["collector"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-prometheus.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-metrics.git", "1.0.0"..<"3.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "collector",
            dependencies: [
                .product(name: "Prometheus", package: "swift-prometheus"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "Vapor", package: "vapor"),
            ])
    ]
)
