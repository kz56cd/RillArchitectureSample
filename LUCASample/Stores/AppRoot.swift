import Architecture
import Observation

/// アプリの一番上のストア
///
/// ログインの画面とタブの画面を、子のストアとして持って出し分ける。
/// 子から届いた Action(ログインできた、ログアウトを押した)を見て切り替える。
@Observable
final class AppRoot: Composable {

    enum Screen {
        case login(Login)
        case main(HomeTabs)
    }

    // MARK: State

    private(set) var screen: Screen

    // MARK: Properties

    private let appDependencies: AppDependencies
    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, action: @escaping (Action) async -> Void = { _ in }) {
        // 子へ渡すクロージャは self を使うが、init が終わるまで self を捕まえられない。
        // 弱参照の変数を先に捕まえておき、最後に self を入れる。
        weak var parent: AppRoot?
        screen = .login(Login(appDependencies, action: { await parent?.send(.login($0)) }))
        self.appDependencies = appDependencies
        self.action = action
        parent = self
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .login(.signInResponse(.success)):
            screen = .main(HomeTabs(appDependencies, action: { [weak self] in await self?.send(.main($0)) }))

        case .main(.signOutButtonTapped):
            screen = .login(Login(appDependencies, action: { [weak self] in await self?.send(.login($0)) }))

        case .login, .main:
            break
        }
    }

    enum Action: Sendable {
        case login(Login.Action)
        case main(HomeTabs.Action)
    }
}
