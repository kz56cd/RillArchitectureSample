import Rill
import Observation

/// タブの画面のストア
///
/// 記録する画面と一覧の画面の 2 つの子を持ち、兄弟の間の連携を中継する。
/// 記録する画面で保存したら、一覧の画面へ `logAdded` を送る。
/// ディープリンクが届いたら、タブを選び、行き先の画面へ `send` で渡す。
@Observable
final class HomeTabs: Composable {

    struct State {
        let newLog: NewLog
        let logList: LogList
        var selectedTab: Tab = .newLog
    }

    enum Tab: Hashable {
        case newLog
        case logList
    }

    // MARK: State

    private(set) var state: State

    // MARK: Properties

    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, action: @escaping (Action) async -> Void = { _ in }) {
        // self を捕まえる方法は AppRoot の init と同じ。
        weak var parent: HomeTabs?
        state = State(
            newLog: NewLog(appDependencies, action: { await parent?.send(.newLog($0)) }),
            logList: LogList(appDependencies, action: { await parent?.send(.logList($0)) })
        )
        self.action = action
        parent = self
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case let .newLog(.form(.saveResponse(.success(saved)))):
            // 兄弟への連携。記録する画面の状態には触らず、一覧へ Action を送る。
            await state.logList.send(.logAdded(saved))

        case let .tabSelected(tab):
            state.selectedTab = tab

        case let .deepLinkOpened(link):
            switch link {
            case .newLog:
                state.selectedTab = .newLog
                await state.newLog.send(.linkOpened)
            case .logList:
                state.selectedTab = .logList
                await state.logList.send(.linkOpened(logID: nil))
            case let .log(id):
                state.selectedTab = .logList
                await state.logList.send(.linkOpened(logID: id))
            }

        case .signOutButtonTapped:
            // 画面の切り替えは親(AppRoot)が行う。
            break

        case .newLog, .logList:
            break
        }
    }

    enum Action: Sendable {
        case tabSelected(Tab)
        /// 親(AppRoot)が中継して送る
        case deepLinkOpened(AppLink)
        case signOutButtonTapped
        case newLog(NewLog.Action)
        case logList(LogList.Action)
    }
}
