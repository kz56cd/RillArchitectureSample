import Foundation
import Rill
@testable import RillArchitectureSample
import Testing

/// 子のストアを積む(push)、シートで出す連携のテスト
struct LogListTests {

    @Test func send_task_記録を読み込む() async {
        let log = ReadingLog.fixture()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.fetchAll = { [log] }
        }
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient))

        await sut.send(.task)

        #expect(sut.state.logs == [log])
        #expect(sut.state.loadFailed == false)
    }

    @Test func send_task_読み込みに失敗_失敗を示す() async {
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.fetchAll = { throw TestError() }
        }
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient))

        await sut.send(.task)

        #expect(sut.state.loadFailed)
    }

    @Test func send_logAdded_同じ記録は二重に足さない() async {
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(), state: .init(logs: [log]))

        await sut.send(.logAdded(log))

        #expect(sut.state.logs == [log])
    }

    @Test func send_logTapped_詳しい画面を積む() async {
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(), state: .init(logs: [log]))

        await sut.send(.logTapped(log))

        #expect(sut.state.path.count == 1)
        #expect(sut.topDetail?.state.log == log)
    }

    @Test func send_pathPopped_残った数まで戻る() async {
        let first = ReadingLog.fixture(title: "一冊目")
        let second = ReadingLog.fixture(title: "二冊目")
        let sut = LogList(.testDependencies(), state: .init(logs: [first, second]))
        await sut.send(.logTapped(first))
        await sut.send(.logTapped(second))
        let bottom = sut.state.path[0]

        await sut.send(.pathPopped(count: 1))

        #expect(sut.state.path == [bottom])
        #expect(sut.topDetail?.state.log == first)
    }

    @Test func send_子のdeleteButtonTapped_一覧から消して戻る() async throws {
        let deleted = Recorder<ReadingLog.ID>()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { await deleted.record($0) }
        }
        let first = ReadingLog.fixture(title: "一冊目")
        let second = ReadingLog.fixture(title: "二冊目")
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient), state: .init(logs: [first, second]))
        await sut.send(.logTapped(first))
        let detail = try #require(sut.topDetail)

        await detail.send(.deleteButtonTapped)

        #expect(deleted.values == [first.id])
        #expect(sut.state.logs == [second])
        #expect(sut.state.path.isEmpty)
    }

    @Test func send_子のdeleteButtonTapped_削除に失敗_積んだまま失敗を示す() async throws {
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { _ in throw TestError() }
        }
        let log = ReadingLog.fixture()
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient), state: .init(logs: [log]))
        await sut.send(.logTapped(log))
        let detail = try #require(sut.topDetail)

        await detail.send(.deleteButtonTapped)

        #expect(sut.state.path == [.detail(detail)])
        #expect(detail.state.deleteFailed)
        #expect(sut.state.logs == [log])
    }

    @Test func send_filterButtonTapped_今の絞り込みでシートを出す() async {
        let sut = LogList(.testDependencies(), state: .init(minimumRating: 3))

        await sut.send(.filterButtonTapped)

        #expect(sut.state.filter?.state.minimumRating == 3)
    }

    @Test func send_子のratingSelected_絞り込んで閉じる() async throws {
        let high = ReadingLog.fixture(title: "高い", rating: 5)
        let low = ReadingLog.fixture(title: "低い", rating: 2)
        let unrated = ReadingLog.fixture(title: "評価なし", rating: nil)
        let sut = LogList(.testDependencies(), state: .init(logs: [high, low, unrated]))
        await sut.send(.filterButtonTapped)
        let filter = try #require(sut.state.filter)

        await filter.send(.ratingSelected(4))

        #expect(sut.state.minimumRating == 4)
        #expect(sut.state.visibleLogs == [high])
        #expect(sut.state.filter == nil)

        await sut.send(.filterButtonTapped)
        await sut.state.filter?.send(.ratingSelected(nil))

        #expect(sut.state.visibleLogs == [high, low, unrated])
    }

    @Test func send_子のcancelButtonTapped_絞り込みを変えずに閉じる() async throws {
        let sut = LogList(.testDependencies(), state: .init(minimumRating: 3))
        await sut.send(.filterButtonTapped)
        let filter = try #require(sut.state.filter)

        await filter.send(.cancelButtonTapped)

        #expect(sut.state.filter == nil)
        #expect(sut.state.minimumRating == 3)
    }

    @Test func send_filterDismissed_シートを閉じる() async {
        let sut = LogList(.testDependencies())
        await sut.send(.filterButtonTapped)

        await sut.send(.filterDismissed)

        #expect(sut.state.filter == nil)
    }

    // MARK: ディープリンク

    @Test func send_linkOpened_読み込んでいない記録_読み込んでから詳しい画面だけを積む() async {
        let log = ReadingLog.fixture()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.fetchAll = { [log] }
        }
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient))

        await sut.send(.linkOpened(logID: log.id))

        #expect(sut.state.logs == [log])
        #expect(sut.state.path.count == 1)
        #expect(sut.topDetail?.state.log == log)
    }

    @Test func send_linkOpened_ほかの画面を開いていても_閉じてから積む() async {
        let first = ReadingLog.fixture(title: "一冊目")
        let second = ReadingLog.fixture(title: "二冊目")
        let sut = LogList(.testDependencies(), state: .init(logs: [first, second]))
        await sut.send(.logTapped(first))
        await sut.send(.filterButtonTapped)

        await sut.send(.linkOpened(logID: second.id))

        #expect(sut.state.filter == nil)
        #expect(sut.state.path.count == 1)
        #expect(sut.topDetail?.state.log == second)
    }

    @Test func send_linkOpened_見つからない記録_一覧のまま見つからないことを示す() async {
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.fetchAll = { [] }
        }
        let sut = LogList(.testDependencies(readingLogClient: readingLogClient))

        await sut.send(.linkOpened(logID: UUID()))

        #expect(sut.state.path.isEmpty)
        #expect(sut.state.linkedLogMissing)
    }
}
