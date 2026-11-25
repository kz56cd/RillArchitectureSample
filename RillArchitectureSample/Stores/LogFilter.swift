import Rill
import Observation

/// 一覧を評価で絞り込む画面(シート)のストア
///
/// 選んだ評価は親(LogList)が受け取って絞り込み、シートを閉じる。
/// 自分の状態は変えないので、`reduce` を書かない。
@Observable
final class LogFilter: Composable, Identifiable {

    struct State {
        /// 今の絞り込み。nil ならすべて
        let minimumRating: Int?
    }

    // MARK: State

    private(set) var state: State

    // MARK: Properties

    let action: (Action) async -> Void

    // MARK: Initializers

    init(state: State, action: @escaping (Action) async -> Void = { _ in }) {
        self.state = state
        self.action = action
    }

    enum Action: Sendable {
        /// nil は「すべて」
        case ratingSelected(Int?)
        case cancelButtonTapped
    }
}
