import Rill
import Observation

/// 1 件の記録の詳しい画面のストア
@Observable
final class LogDetail: Composable, Identifiable {

    struct State {
        let log: ReadingLog
        var isDeleting = false
        var deleteFailed = false
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
        case .closeButtonTapped:
            // 閉じるのは親(LogList)が行う。
            break

        case .deleteButtonTapped:
            state.isDeleting = true
            state.deleteFailed = false
            do {
                try await readingLogClient.delete(state.log.id)
                await send(.deleteResponse(.success(state.log.id)))
            } catch {
                await send(.deleteResponse(.failure(error)))
            }

        case .deleteResponse(.success):
            // 一覧から消して閉じるのは親(LogList)が行う。
            state.isDeleting = false

        case .deleteResponse(.failure):
            state.isDeleting = false
            state.deleteFailed = true
        }
    }

    enum Action: Sendable {
        case closeButtonTapped
        case deleteButtonTapped
        case deleteResponse(Result<ReadingLog.ID, any Error>)
    }
}
