// swift-tools-version: 5.7

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
