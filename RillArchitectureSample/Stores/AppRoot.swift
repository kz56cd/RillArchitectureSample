import Rill
import Observation

/// アプリの一番上のストア
///
/// ログインの画面とタブの画面を、子のストアとして持って出し分ける。
/// 子から届いた Action(ログインできた、ログアウトを押した)を見て切り替える。
///
/// ディープリンクは、まずここに届く。ログインしていれば、タブの画面へ `send` で渡す。
/// ログインしていなければ行き先を覚えておき、ログインできたら渡す。
@Observable
final class AppRoot: Composable {

    struct State {
        var screen: Screen
        /// ログインする前に開かれたディープリンク。ログインできたら開く
        var pendingLink: AppLink?
    }

    enum Screen {
        case login(Login)
        case main(HomeTabs)
    }

    // MARK: State

    private(set) var state: State

    // MARK: Properties

    private let appDependencies: AppDependencies
    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, action: @escaping (Action) async -> Void = { _ in }) {
        // 子へ渡すクロージャは self を使うが、init が終わるまで self を捕まえられない。
        // 弱参照の変数を先に捕まえておき、最後に self を入れる。
        weak var parent: AppRoot?
        state = State(screen: .login(Login(appDependencies, action: { await parent?.send(.login($0)) })))
        self.appDependencies = appDependencies
        self.action = action
        parent = self
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case let .deepLinkOpened(link):
            switch state.screen {
            case .login:
                state.pendingLink = link
            case let .main(homeTabs):
                await homeTabs.send(.deepLinkOpened(link))
            }

        case .login(.signInResponse(.success)):
            let homeTabs = HomeTabs(appDependencies, action: { [weak self] in await self?.send(.main($0)) })
            state.screen = .main(homeTabs)
            if let link = state.pendingLink {
                state.pendingLink = nil
                await homeTabs.send(.deepLinkOpened(link))
            }

        case .main(.signOutButtonTapped):
            state.screen = .login(Login(appDependencies, action: { [weak self] in await self?.send(.login($0)) }))

        case .login, .main:
            break
        }
    }

    enum Action: Sendable {
        /// URL で開かれた。`onDeepLink` が送る
        case deepLinkOpened(AppLink)
        case login(Login.Action)
        case main(HomeTabs.Action)
    }
}
