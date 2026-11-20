// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Rill",
    defaultLocalization: "ja",
    // macOS でも組めるようにして、`swift test` で手早くテストを流せるようにする。
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "Rill", targets: ["Rill"])
    ],
    targets: [
        .target(
            name: "Rill",
            // ストアは MainActor で動かす。宣言ごとに @MainActor を書かない。
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "RillTests",
            dependencies: ["Rill"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
