import Architecture
@testable import LUCASample
import Testing

/// 1 つのストアの単体テスト
///
/// 依存を差し替えてストアを作り、`send` して、状態と親へ届いた Action を確かめる。
struct LogFormTests {

    @Test func send_saveButtonTapped_正しい値_保存して親へ伝える() async throws {
        let saved = Recorder<ReadingLogInput>()
        let parent = Recorder<LogForm.Action>()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.save = { input in
                await saved.record(input)
                return .fixture(title: input.title, pages: input.pages, rating: input.rating)
            }
        }
        let sut = LogForm(
            .testDependencies(readingLogClient: readingLogClient),
            draft: ReadingLogDraft(title: "見本の本", pages: "120", rating: ""),
            action: { parent.record($0) }
        )

        await sut.send(.saveButtonTapped)

        #expect(saved.values == [ReadingLogInput(title: "見本の本", pages: 120, rating: nil)])
        #expect(sut.invalidFields.isEmpty)
        #expect(sut.isSaving == false)
        // 子は自分の状態を確定してから親へ伝える。保存の結果が先に、押した操作があとに届く。
        let actions = parent.values
        try #require(actions.count == 2)
        guard case .saveResponse(.success) = actions[0], case .saveButtonTapped = actions[1] else {
            Issue.record("親へ届いた Action が想定と違う: \(actions)")
            return
        }
    }

    @Test func send_saveButtonTapped_範囲外_保存せず欄を示す() async {
        let saved = Recorder<ReadingLogInput>()
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.save = { input in
                await saved.record(input)
                return .fixture()
            }
        }
        let sut = LogForm(
            .testDependencies(readingLogClient: readingLogClient),
            draft: ReadingLogDraft(title: " ", pages: "0", rating: "3")
        )

        await sut.send(.saveButtonTapped)

        #expect(saved.values.isEmpty)
        #expect(sut.invalidFields == [.title, .pages])
    }

    @Test func send_saveButtonTapped_保存に失敗_失敗を示す() async {
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.save = { _ in throw TestError() }
        }
        let sut = LogForm(
            .testDependencies(readingLogClient: readingLogClient),
            draft: ReadingLogDraft(title: "見本の本", pages: "120", rating: "")
        )

        await sut.send(.saveButtonTapped)

        #expect(sut.saveFailed)
        #expect(sut.isSaving == false)
    }
}
