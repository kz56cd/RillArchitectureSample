// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Rill",
    defaultLocalization: "ja",
    // Rill の本体は Packages/Rill にある。Swift Package Manager の依存として使えるよう、パッケージの定義はリポジトリの直下に置く。
    // macOS でも組めるようにして、`swift test` で手早くテストを流せるようにする。
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "Rill", targets: ["Rill"])
    ],
    traits: [
        // 多言語化しないアプリ向け。有効にすると `DisplayText` が `String` そのものになる。
        // 多言語化するかどうかはアプリ全体で決めるので、アプリで 1 度だけ選ぶ。
        .trait(name: "NoLocalization", description: "多言語化しないアプリ向け。DisplayText を String そのものにする")
    ],
    targets: [
        .target(
            name: "Rill",
            path: "Packages/Rill/Sources/Rill",
            // ストアは MainActor で動かす。宣言ごとに @MainActor を書かない。
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "RillTests",
            dependencies: ["Rill"],
            path: "Packages/Rill/Tests/RillTests",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
