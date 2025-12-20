// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PHInteractiveDismissible",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PHInteractiveDismissible",
            targets: ["PHInteractiveDismissible"]),
    ],
    dependencies: [
      .package(url: "https://github.com/jtrivedi/Wave.git", .branchItem("main"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PHInteractiveDismissible",
            dependencies: [
              .product(name: "Wave", package: "Wave")
            ]),
        .testTarget(
            name: "PHInteractiveDismissibleTests",
            dependencies: ["PHInteractiveDismissible"]),
    ]
)
