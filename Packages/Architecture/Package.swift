// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Architecture",
    defaultLocalization: "ja",
    // macOS でも組めるようにして、`swift test` で手早くテストを流せるようにする。
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "Architecture", targets: ["Architecture"])
    ],
    targets: [
        .target(
            name: "Architecture",
            // ストアは MainActor で動かす。宣言ごとに @MainActor を書かない。
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "ArchitectureTests",
            dependencies: ["Architecture"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
