// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Swift-CQuickJS",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "CQuickJSStatic", targets: ["CQuickJSStatic"]),
        .library(name: "CQuickJSDynamic", targets: ["CQuickJSDynamic"]),
        .library(name: "CQuickJSSystem", targets: ["CQuickJSSystem"]),
    ],
    targets: [
        .binaryTarget(
            name: "CQuickJSStatic",
            url: "https://github.com/ghostflyby/Swift-CQuickJS/releases/download/0.14.0-pack.1/cquickjs-static.xcframework.zip",
            checksum: "0a0e4593f8cb84724052cf20990bde27901c04d0f73327d778117bffe6f58210"
        ),
        .binaryTarget(
            name: "CQuickJSDynamic",
            url: "https://github.com/ghostflyby/Swift-CQuickJS/releases/download/0.14.0-pack.1/cquickjs-dynamic.xcframework.zip",
            checksum: "d52dbd15b386acda2adb7002d5eaa6fb95a26c4f11f3bf578a1cfa34b814dd9c"
        ),
        .systemLibrary(
            name: "CQuickJSSystem",
            path: "Sources/CQuickJSSystem",
            pkgConfig: "quickjs-ng",
            providers: [
                .brew(["quickjs-ng"]),
            ]
        )
    ]
)
