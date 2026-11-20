/// アプリの依存のまとまり
///
/// ストアは init で受け取り、子のストアを作るときにそのまま渡す。
struct AppDependencies: Sendable {

    // MARK: Static Properties

    static let live = AppDependencies(authClient: .liveValue, readingLogClient: .liveValue)

    // MARK: Properties

    var authClient: AuthClient
    var readingLogClient: ReadingLogClient

    // MARK: Static Functions

    /// テスト用の依存。渡さなかったものは `testValue` になる。
    static func testDependencies(
        authClient: AuthClient = .testValue,
        readingLogClient: ReadingLogClient = .testValue
    ) -> AppDependencies {
        AppDependencies(authClient: authClient, readingLogClient: readingLogClient)
    }
}
