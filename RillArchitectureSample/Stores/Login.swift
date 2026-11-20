import Rill
import Foundation
import Observation

/// ログインの画面のストア
@Observable
final class Login: Composable {

    struct State {
        var userID = ""
        var isSigningIn = false
        var errorMessage: String?
    }

    // MARK: State

    private(set) var state: State

    /// 入力欄の値。`TextField` は同期で書き換える必要があるので、例外として View から直接束縛させる。
    var userID: String {
        get { state.userID }
        set { state.userID = newValue }
    }

    // MARK: Properties

    private let authClient: AuthClient
    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, state: State = State(), action: @escaping (Action) async -> Void = { _ in }) {
        self.state = state
        authClient = appDependencies.authClient
        self.action = action
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .loginButtonTapped:
            let userID = state.userID.trimmingCharacters(in: .whitespaces)
            guard !userID.isEmpty else {
                state.errorMessage = "ユーザー ID を入力してください"
                return
            }
            state.isSigningIn = true
            state.errorMessage = nil
            do {
                try await authClient.signIn(userID)
                await send(.signInResponse(.success(())))
            } catch {
                await send(.signInResponse(.failure(error)))
            }

        case .signInResponse(.success):
            // 画面の切り替えは親(AppRoot)が行う。
            state.isSigningIn = false

        case .signInResponse(.failure):
            state.isSigningIn = false
            state.errorMessage = "ログインできませんでした"
        }
    }

    enum Action: Sendable {
        case loginButtonTapped
        case signInResponse(Result<Void, any Error>)
    }
}
