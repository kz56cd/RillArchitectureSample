import Rill

/// アプリの依存のまとまり
///
/// ストアは init で受け取り、子のストアを作るときにそのまま渡す。
struct AppDependencies: Sendable {

    // MARK: Static Properties

    static let live = AppDependencies(authClient: .liveValue, readingLogClient: .liveValue, notificationClient: .liveValue)

    // MARK: Properties

    var authClient: AuthClient
    var readingLogClient: ReadingLogClient
    var notificationClient: NotificationClient

    // MARK: Static Functions

    /// テスト用の依存。渡さなかったものは `testValue` になる。
    static func testDependencies(
        authClient: AuthClient = .testValue,
        readingLogClient: ReadingLogClient = .testValue,
        notificationClient: NotificationClient = .testValue
    ) -> AppDependencies {
        AppDependencies(authClient: authClient, readingLogClient: readingLogClient, notificationClient: notificationClient)
    }
}
