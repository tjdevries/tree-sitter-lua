// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TreeSitterLua",
    products: [
        .library(name: "TreeSitterLua", targets: ["TreeSitterLua"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterLua",
            dependencies: [],
            path: ".",
            sources: [
                "src/parser.c",
                // NOTE: if your language has an external scanner, add it here.
            ],
            resources: [
                .copy("queries")
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),
        .testTarget(
            name: "TreeSitterLuaTests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterLua",
            ],
            path: "bindings/swift/TreeSitterLuaTests"
        )
    ],
    cLanguageStandard: .c11
)
