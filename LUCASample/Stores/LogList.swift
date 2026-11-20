import Architecture
import Observation

/// 記録の一覧の画面のストア
///
/// 記録の一覧を持つ。記録を選ぶと、詳しい画面を子のストア(`detail`)としてシートで出す。
@Observable
final class LogList: Composable {

    // MARK: State

    private(set) var logs: [ReadingLog]
    private(set) var detail: LogDetail?
    private(set) var loadFailed: Bool

    // MARK: Properties

    private let appDependencies: AppDependencies
    let action: (Action) async -> Void

    // MARK: Initializers

    init(
        _ appDependencies: AppDependencies,
        logs: [ReadingLog] = [],
        loadFailed: Bool = false,
        action: @escaping (Action) async -> Void = { _ in }
    ) {
        self.logs = logs
        detail = nil
        self.loadFailed = loadFailed
        self.appDependencies = appDependencies
        self.action = action
    }

    // MARK: Functions

    func reduce(_ action: Action) async {
        switch action {
        case .task:
            do {
                let logs = try await appDependencies.readingLogClient.fetchAll()
                await send(.fetchResponse(.success(logs)))
            } catch {
                await send(.fetchResponse(.failure(error)))
            }

        case let .fetchResponse(.success(logs)):
            self.logs = logs
            loadFailed = false

        case .fetchResponse(.failure):
            loadFailed = true

        case let .logAdded(log):
            guard !logs.contains(where: { $0.id == log.id }) else {
                return
            }
            logs.insert(log, at: 0)

        case let .logTapped(log):
            detail = LogDetail(appDependencies, log: log, action: { [weak self] in await self?.send(.detail($0)) })

        case .detailDismissed, .detail(.closeButtonTapped):
            detail = nil

        case let .detail(.deleteResponse(.success(id))):
            logs.removeAll { $0.id == id }
            detail = nil

        case .detail:
            break
        }
    }

    enum Action: Sendable {
        case task
        case fetchResponse(Result<[ReadingLog], any Error>)
        /// 兄弟(記録する画面)で保存した記録。親の HomeTabs が中継して送る
        case logAdded(ReadingLog)
        case logTapped(ReadingLog)
        /// シートを下へのスワイプで閉じた
        case detailDismissed
        case detail(LogDetail.Action)
    }
}
