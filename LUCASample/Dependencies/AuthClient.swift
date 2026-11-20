/// ログインの接続
struct AuthClient: DependencyClient {

    // MARK: Static Properties

    /// 見本なので、通信の代わりに少し待つ。ユーザー ID が "error" のときだけ失敗にする。
    static let liveValue = AuthClient(signIn: { userID in
        try await Task.sleep(for: .milliseconds(300))
        if userID == "error" {
            throw AuthError.rejected
        }
    })

    static let testValue = AuthClient(signIn: { _ in })

    // MARK: Properties

    /// ログインする。失敗したときは throw する。
    var signIn: @Sendable (_ userID: String) async throws -> Void
}

nonisolated enum AuthError: Error {
    case rejected
}
