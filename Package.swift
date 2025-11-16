// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DynamoModel",
    products: [
        .library(
            name: "DynamoModel",
            targets: ["DynamoModel"]
        ),
    ],
    targets: [
        .target(name: "DynamoModel"),
        .testTarget(
            name: "DynamoModelTests",
            dependencies: ["DynamoModel"]
        ),
    ]
)
