import Rill
import Observation

/// 記録の一覧の画面のストア
///
/// 記録の一覧を持つ。記録を選ぶと、詳しい画面を子のストアとして `path` に積む(push)。
/// 絞り込みの画面は、子のストア(`filter`)としてシートで出す。
@Observable
final class LogList: Composable {

    struct State {
        var logs: [ReadingLog] = []
        var loadFailed = false
        /// 評価で絞り込む。nil ならすべて
        var minimumRating: Int?
        /// 積んだ画面。先頭が一番下
        var path: [Destination] = []
        var filter: LogFilter?

        /// 絞り込んだあとの記録
        var visibleLogs: [ReadingLog] {
            guard let minimumRating else {
                return logs
            }
            return logs.filter { ($0.rating ?? 0) >= minimumRating }
        }
    }

    /// 一覧から積む画面。画面が増えたら case を足す
    enum Destination: Hashable {
        case detail(LogDetail)
    }

    // MARK: State

    private(set) var state: State

    // MARK: Properties

    private let appDependencies: AppDependencies
    let action: (Action) async -> Void

    // MARK: Initializers

    init(_ appDependencies: AppDependencies, state: State = State(), action: @escaping (Action) async -> Void = { _ in }) {
        self.state = state
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
            state.logs = logs
            state.loadFailed = false

        case .fetchResponse(.failure):
            state.loadFailed = true

        case let .logAdded(log):
            guard !state.logs.contains(where: { $0.id == log.id }) else {
                return
            }
            state.logs.insert(log, at: 0)

        case let .logTapped(log):
            let detail = LogDetail(appDependencies, state: .init(log: log), action: { [weak self] in await self?.send(.detail($0)) })
            state.path.append(.detail(detail))

        case let .pathPopped(count):
            state.path.removeLast(state.path.count - count)

        case let .detail(.deleteResponse(.success(id))):
            state.logs.removeAll { $0.id == id }
            // 消した記録の画面から戻る。
            state.path.removeAll { destination in
                guard case let .detail(detail) = destination else { return false }
                return detail.state.log.id == id
            }

        case .detail:
            break

        case .filterButtonTapped:
            state.filter = LogFilter(state: .init(minimumRating: state.minimumRating), action: { [weak self] in await self?.send(.filter($0)) })

        case let .filter(.ratingSelected(rating)):
            state.minimumRating = rating
            state.filter = nil

        case .filterDismissed, .filter(.cancelButtonTapped):
            state.filter = nil
        }
    }

    enum Action: Sendable {
        case task
        case fetchResponse(Result<[ReadingLog], any Error>)
        /// 兄弟(記録する画面)で保存した記録。親の HomeTabs が中継して送る
        case logAdded(ReadingLog)
        case logTapped(ReadingLog)
        /// 戻るボタンや端からのスワイプで戻った。値は残った画面の数
        case pathPopped(count: Int)
        case detail(LogDetail.Action)
        case filterButtonTapped
        /// シートを下へのスワイプで閉じた
        case filterDismissed
        case filter(LogFilter.Action)
    }
}
