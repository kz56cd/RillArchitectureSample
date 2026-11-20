import Foundation
import Observation

/// ログインの画面のストア
@Observable
final class Login: Composable {

    // MARK: State

    /// 入力欄の値。`TextField` は同期で書き換える必要があるので、例外として View から直接束縛させる。
    var userID: String
    private(set) var isSigningIn: Bool
    private(set) var errorMessage: String?

    // MARK: Properties

    private let authClient: AuthClient
    let action: (Action) async -> Void

    // MARK: Initializers

    init(
        _ appDependencies: AppDependencies,
        userID: String = "",
        isSigningIn: Bool = false,
        errorMessage: String? = nil,
        action: @escaping (Action) async -> Void = { _ in }
    ) {
        self.userID = userID
        self.isSigningIn = isSigningIn
        self.errorMessage = errorMessage
        authClient = appDependencies.authClient
        self.action = action
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .loginButtonTapped:
            let userID = userID.trimmingCharacters(in: .whitespaces)
            guard !userID.isEmpty else {
                errorMessage = "ユーザー ID を入力してください"
                return
            }
            isSigningIn = true
            errorMessage = nil
            do {
                try await authClient.signIn(userID)
                await send(.signInResponse(.success(())))
            } catch {
                await send(.signInResponse(.failure(error)))
            }

        case .signInResponse(.success):
            // 画面の切り替えは親(AppRoot)が行う。
            isSigningIn = false

        case .signInResponse(.failure):
            isSigningIn = false
            errorMessage = "ログインできませんでした"
        }
    }

    enum Action: Sendable {
        case loginButtonTapped
        case signInResponse(Result<Void, any Error>)
    }
}
