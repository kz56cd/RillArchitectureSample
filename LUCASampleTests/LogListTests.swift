import Testing
@testable import LUCASample

/// 子のストアをシートで出す連携のテスト
struct LogListTests {

    @Test func send_task_記録を読み込む() async {
        let log = ReadingLog.fixture()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.fetchAll = { [log] }
        }
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient))

        await sut.send(.task)

        #expect(sut.logs == [log])
        #expect(sut.loadFailed == false)
    }

    @Test func send_task_読み込みに失敗_失敗を示す() async {
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.fetchAll = { throw TestError() }
        }
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient))

        await sut.send(.task)

        #expect(sut.loadFailed)
    }

    @Test func send_logAdded_同じ記録は二重に足さない() async {
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(), logs: [log])

        await sut.send(.logAdded(log))

        #expect(sut.logs == [log])
    }

    @Test func send_logTapped_詳しい画面を出す() async {
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(), logs: [log])

        await sut.send(.logTapped(log))

        #expect(sut.detail?.log == log)
    }

    @Test func send_子のcloseButtonTapped_詳しい画面を閉じる() async throws {
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(), logs: [log])
        await sut.send(.logTapped(log))
        let detail = try #require(sut.detail)

        await detail.send(.closeButtonTapped)

        #expect(sut.detail == nil)
        #expect(sut.logs == [log])
    }

    @Test func send_detailDismissed_詳しい画面を閉じる() async {
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(), logs: [log])
        await sut.send(.logTapped(log))

        await sut.send(.detailDismissed)

        #expect(sut.detail == nil)
    }

    @Test func send_子のdeleteButtonTapped_一覧から消して閉じる() async throws {
        let deleted = Recorder<ReadingLog.ID>()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { await deleted.record($0) }
        }
        let first = ReadingLog.fixture(title: "一冊目")
        let second = ReadingLog.fixture(title: "二冊目")
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient), logs: [first, second])
        await sut.send(.logTapped(first))
        let detail = try #require(sut.detail)

        await detail.send(.deleteButtonTapped)

        #expect(deleted.values == [first.id])
        #expect(sut.logs == [second])
        #expect(sut.detail == nil)
    }

    @Test func send_子のdeleteButtonTapped_削除に失敗_開いたまま失敗を示す() async throws {
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { _ in throw TestError() }
        }
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient), logs: [log])
        await sut.send(.logTapped(log))
        let detail = try #require(sut.detail)

        await detail.send(.deleteButtonTapped)

        #expect(sut.detail === detail)
        #expect(detail.deleteFailed)
        #expect(sut.logs == [log])
    }
}
