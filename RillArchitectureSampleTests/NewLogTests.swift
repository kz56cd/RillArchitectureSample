import Testing
@testable import RillArchitectureSample

/// 親子の連携のテスト
///
/// 子へ `send` すると、子の Action が親の `reduce` に届き、親の状態が変わることを確かめる。
/// View を立ち上げずに確かめられる。
struct NewLogTests {

    @Test func send_子のsaveButtonTapped_正しい値_保存したあとへ切り替わる() async throws {
        let sut = NewLog(.testDependencies())
        let child = try #require(sut.form)
        child.draft = ReadingLogDraft(title: "見本の本", pages: "120", rating: "5")

        await child.send(.saveButtonTapped)

        let saved = try #require(sut.saved)
        #expect(saved.title == "見本の本")
        #expect(saved.pages == 120)
        #expect(saved.rating == 5)
    }

    @Test func send_子のsaveButtonTapped_範囲外_入力中のまま() async throws {
        let sut = NewLog(.testDependencies())
        let child = try #require(sut.form)
        child.draft = ReadingLogDraft(title: "", pages: "120", rating: "")

        await child.send(.saveButtonTapped)

        #expect(sut.form === child)
    }

    @Test func send_writeAnotherButtonTapped_新しい入力欄に戻る() async throws {
        let sut = NewLog(.testDependencies())
        let firstChild = try #require(sut.form)
        firstChild.draft = ReadingLogDraft(title: "見本の本", pages: "120", rating: "")
        await firstChild.send(.saveButtonTapped)

        await sut.send(.writeAnotherButtonTapped)

        let secondChild = try #require(sut.form)
        #expect(secondChild !== firstChild)
        #expect(secondChild.draft == ReadingLogDraft())
    }

    @Test func send_writeAnotherButtonTapped_新しい子も親へつながっている() async throws {
        let sut = NewLog(.testDependencies())
        await sut.form?.send(.saveButtonTapped)  // 空なので保存されない
        await sut.send(.writeAnotherButtonTapped)
        let child = try #require(sut.form)
        child.draft = ReadingLogDraft(title: "二冊目", pages: "300", rating: "")

        await child.send(.saveButtonTapped)

        #expect(sut.saved?.title == "二冊目")
    }
}
