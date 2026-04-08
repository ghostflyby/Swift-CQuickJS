// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Swift-CQuickJS",
    products: [
        .library(
            name: "CQuickJS",
            targets: ["CQuickJS"]
        ),
    ],
    targets: [
        .target(
            name: "CQuickJS",
            path: ".",
            exclude: [
                ".build",
                ".git",
                ".gitignore",
            ],
            sources: [
                "Vendor/quickjs/dtoa.c",
                "Vendor/quickjs/libregexp.c",
                "Vendor/quickjs/libunicode.c",
                "Vendor/quickjs/quickjs.c",
            ],
            publicHeadersPath: "Sources/CQuickJS/include",
            cSettings: [
                .headerSearchPath("Vendor/quickjs"),
                .define("_GNU_SOURCE", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("m", .when(platforms: [.linux])),
                .linkedLibrary("dl", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
            ]
        ),
        .testTarget(
            name: "CQuickJSTests",
            dependencies: ["CQuickJS"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
