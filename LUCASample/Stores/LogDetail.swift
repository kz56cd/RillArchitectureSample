import Architecture
import Observation

/// 1 件の記録の詳しい画面のストア
@Observable
final class LogDetail: Composable, Identifiable {

    // MARK: State

    let log: ReadingLog
    private(set) var isDeleting: Bool
    private(set) var deleteFailed: Bool

    // MARK: Properties

    private let readingLogClient: ReadingLogClient
    let action: (Action) async -> Void

    // MARK: Initializers

    init(
        _ appDependencies: AppDependencies,
        log: ReadingLog,
        isDeleting: Bool = false,
        deleteFailed: Bool = false,
        action: @escaping (Action) async -> Void = { _ in }
    ) {
        self.log = log
        self.isDeleting = isDeleting
        self.deleteFailed = deleteFailed
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
            isDeleting = true
            deleteFailed = false
            do {
                try await readingLogClient.delete(log.id)
                await send(.deleteResponse(.success(log.id)))
            } catch {
                await send(.deleteResponse(.failure(error)))
            }

        case .deleteResponse(.success):
            // 一覧から消して閉じるのは親(LogList)が行う。
            isDeleting = false

        case .deleteResponse(.failure):
            isDeleting = false
            deleteFailed = true
        }
    }

    enum Action: Sendable {
        case closeButtonTapped
        case deleteButtonTapped
        case deleteResponse(Result<ReadingLog.ID, any Error>)
    }
}
