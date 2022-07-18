// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreUI",
    products: [
        .library(name: "CoreUI", targets: ["CoreUI"]),
        .library(name: "CommonUI", targets: ["CommonUI"])
    ],
    targets: [
        .target(name: "CoreUI", dependencies: []),
        .target(name: "CommonUI", dependencies: ["CoreUI"])
    ]
)
