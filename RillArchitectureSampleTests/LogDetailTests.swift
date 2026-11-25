import Rill
@testable import RillArchitectureSample
import Testing

/// 確認ダイアログとアラートのテスト
///
/// 中身(タイトル、ボタンと送る Action)は値なので、View を立ち上げずに確かめられる。
struct LogDetailTests {

    @Test func send_deleteButtonTapped_削除してよいかを確かめる() async throws {
        let deleted = Recorder<ReadingLog.ID>()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { await deleted.record($0) }
        }
        let sut = LogDetail(.testDependencies(readingLogClient: readingLogClient), state: .init(log: .fixture()))

        await sut.send(.deleteButtonTapped)

        let confirmation = try #require(sut.state.confirmation)
        #expect(confirmation.title.resolve() == "「見本の本」を削除しますか?")
        #expect(confirmation.buttons.map(\.title) == ["削除する", "キャンセル"])
        #expect(confirmation.buttons.map(\.role) == [.destructive, .cancel])
        // 確かめるまでは消さない。
        #expect(deleted.values.isEmpty)
    }

    @Test func 確認ダイアログの削除するを押す_閉じてから削除する() async throws {
        let deleted = Recorder<ReadingLog.ID>()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { await deleted.record($0) }
        }
        let log = ReadingLog.fixture()
        let parent = Recorder<LogDetail.Action>()
        let sut = LogDetail(.testDependencies(readingLogClient: readingLogClient), state: .init(log: log), action: { parent.record($0) })
        await sut.send(.deleteButtonTapped)
        let confirmation = try #require(sut.state.confirmation)
        let deleteButton = try #require(confirmation.buttons.first { $0.role == .destructive })

        // View の確認ダイアログが、ボタンを押したときにすること
        await sut.send(.confirmationDismissed)
        await sut.send(try #require(deleteButton.action))

        #expect(sut.state.confirmation == nil)
        #expect(deleted.values == [log.id])
    }

    @Test func 確認ダイアログのキャンセルを押す_消さずに閉じる() async throws {
        let deleted = Recorder<ReadingLog.ID>()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { await deleted.record($0) }
        }
        let sut = LogDetail(.testDependencies(readingLogClient: readingLogClient), state: .init(log: .fixture()))
        await sut.send(.deleteButtonTapped)
        let cancelButton = try #require(sut.state.confirmation?.buttons.first { $0.role == .cancel })

        await sut.send(.confirmationDismissed)

        #expect(cancelButton.action == nil)
        #expect(sut.state.confirmation == nil)
        #expect(deleted.values.isEmpty)
    }

    @Test func send_deleteConfirmed_削除に失敗_アラートを出し_閉じると消える() async throws {
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.delete = { _ in throw TestError() }
        }
        let sut = LogDetail(.testDependencies(readingLogClient: readingLogClient), state: .init(log: .fixture()))

        await sut.send(.deleteConfirmed)

        let alert = try #require(sut.state.alert)
        #expect(alert.title == "削除できませんでした")
        #expect(alert.buttons.isEmpty)
        #expect(sut.state.isDeleting == false)

        await sut.send(.alertDismissed)

        #expect(sut.state.alert == nil)
    }
}
