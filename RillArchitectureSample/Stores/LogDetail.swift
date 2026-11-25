import Rill
import Observation

/// 1 件の記録の詳しい画面のストア
///
/// 一覧から積む(push)。`NavigationStack` の path に入れるため、同じストアかどうかで比べる(`IdentityHashable`)。
@Observable
final class LogDetail: Composable, nonisolated IdentityHashable {

    struct State {
        let log: ReadingLog
        var isDeleting = false
        /// 削除してよいかの確認(確認ダイアログ)
        var confirmation: AlertState<Action>?
        /// 削除できなかったことの知らせ(アラート)
        var alert: AlertState<Action>?
    }

    // MARK: State

    private(set) var state: State

    // MARK: Properties

    private let readingLogClient: ReadingLogClient
    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, state: State, action: @escaping (Action) async -> Void = { _ in }) {
        self.state = state
        readingLogClient = appDependencies.readingLogClient
        self.action = action
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .deleteButtonTapped:
            state.confirmation = AlertState(
                // 本の名前を埋め込む。訳すときのキーは「%@」を削除しますか? になる。
                title: "「\(state.log.title)」を削除しますか?",
                message: "削除すると、元に戻せません。",
                buttons: [
                    AlertButton("削除する", role: .destructive, action: .deleteConfirmed),
                    AlertButton("キャンセル", role: .cancel)
                ]
            )

        case .confirmationDismissed:
            state.confirmation = nil

        case .deleteConfirmed:
            state.isDeleting = true
            do {
                try await readingLogClient.delete(state.log.id)
                await send(.deleteResponse(.success(state.log.id)))
            } catch {
                await send(.deleteResponse(.failure(error)))
            }

        case .deleteResponse(.success):
            // 一覧から消して戻るのは親(LogList)が行う。
            state.isDeleting = false

        case .deleteResponse(.failure):
            state.isDeleting = false
            state.alert = AlertState(title: "削除できませんでした", message: "時間をおいて、もう一度お試しください。")

        case .alertDismissed:
            state.alert = nil
        }
    }

    enum Action: Sendable {
        case deleteButtonTapped
        /// 確認ダイアログで「削除する」を押した
        case deleteConfirmed
        /// 確認ダイアログを閉じた(どのボタンでも、外を押しても届く)
        case confirmationDismissed
        case deleteResponse(Result<ReadingLog.ID, any Error>)
        /// アラートを閉じた
        case alertDismissed
    }
}
