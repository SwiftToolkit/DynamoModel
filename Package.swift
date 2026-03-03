// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DynamoModel",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "DynamoModel",
            targets: ["DynamoModel"]
        ),
    ],
    traits: [
        .trait(name: "SotoDynamoDB", description: "Adds CRUD convenience methods using SotoDynamoDB."),
    ],
    dependencies: [
        .package(url: "https://github.com/soto-project/soto.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "DynamoModel",
            dependencies: [
                .product(name: "SotoDynamoDB", package: "soto", condition: .when(traits: ["SotoDynamoDB"])),
            ]
        ),
        .testTarget(
            name: "DynamoModelTests",
            dependencies: ["DynamoModel"]
        ),
    ]
)
