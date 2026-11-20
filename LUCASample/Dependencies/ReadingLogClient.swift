import Architecture
import Foundation

/// 読書の記録の保存先との接続
struct ReadingLogClient: DependencyClient {

    // MARK: Static Properties

    static let liveValue: ReadingLogClient = {
        let database = InMemoryReadingLogDatabase()
        return ReadingLogClient(
            fetchAll: { await database.all() },
            save: { await database.insert($0) },
            delete: { await database.delete($0) }
        )
    }()

    static let testValue = ReadingLogClient(
        fetchAll: { [] },
        save: { ReadingLog(id: UUID(), input: $0, loggedAt: .distantPast) },
        delete: { _ in }
    )

    // MARK: Properties

    /// 新しい順に、すべての記録を読む。
    var fetchAll: @Sendable () async throws -> [ReadingLog]
    /// 記録を保存し、保存した記録を返す。
    var save: @Sendable (ReadingLogInput) async throws -> ReadingLog
    /// 記録を消す。
    var delete: @Sendable (ReadingLog.ID) async throws -> Void
}

/// 見本のための、メモリの中だけの保存先
actor InMemoryReadingLogDatabase {

    // MARK: Properties

    private var logs: [ReadingLog] = []

    // MARK: Functions

    func all() -> [ReadingLog] {
        logs
    }

    func insert(_ input: ReadingLogInput) -> ReadingLog {
        let log = ReadingLog(id: UUID(), input: input, loggedAt: .now)
        logs.insert(log, at: 0)
        return log
    }

    func delete(_ id: ReadingLog.ID) {
        logs.removeAll { $0.id == id }
    }
}
