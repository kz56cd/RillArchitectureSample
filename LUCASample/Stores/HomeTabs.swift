import Architecture
import Observation

/// タブの画面のストア
///
/// 記録する画面と一覧の画面の 2 つの子を持ち、兄弟の間の連携を中継する。
/// 記録する画面で保存したら、一覧の画面へ `logAdded` を送る。
@Observable
final class HomeTabs: Composable {

    // MARK: State

    let newLog: NewLog
    let logList: LogList

    // MARK: Properties

    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, action: @escaping (Action) async -> Void = { _ in }) {
        // self を捕まえる方法は AppRoot の init と同じ。
        weak var parent: HomeTabs?
        newLog = NewLog(appDependencies, action: { await parent?.send(.newLog($0)) })
        logList = LogList(appDependencies, action: { await parent?.send(.logList($0)) })
        self.action = action
        parent = self
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case let .newLog(.form(.saveResponse(.success(saved)))):
            // 兄弟への連携。記録する画面の状態には触らず、一覧へ Action を送る。
            await logList.send(.logAdded(saved))

        case .signOutButtonTapped:
            // 画面の切り替えは親(AppRoot)が行う。
            break

        case .newLog, .logList:
            break
        }
    }

    enum Action: Sendable {
        case signOutButtonTapped
        case newLog(NewLog.Action)
        case logList(LogList.Action)
    }
}
