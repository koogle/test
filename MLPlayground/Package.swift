// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MLPlayground",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MLPlayground",
            targets: ["MLPlayground"]
        )
    ],
    targets: [
        .target(
            name: "MLPlayground",
            path: "Sources/MLPlayground"
        )
    ]
)
