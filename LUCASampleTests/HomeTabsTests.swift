import Testing
@testable import LUCASample

/// 兄弟の連携のテスト
///
/// 記録する画面(孫)で保存すると、親の HomeTabs が中継して、一覧の画面(兄弟)に記録が足されることを確かめる。
struct HomeTabsTests {

    @Test func send_記録する画面で保存_一覧に足される() async throws {
        let sut = HomeTabs(.testDependencies())
        let form = try #require(sut.newLog.form)
        form.draft = ReadingLogDraft(title: "見本の本", pages: "120", rating: "")

        await form.send(.saveButtonTapped)

        let saved = try #require(sut.newLog.saved)
        #expect(sut.logList.logs == [saved])
    }

    @Test func send_signOutButtonTapped_親へ伝える() async throws {
        let parent = Recorder<HomeTabs.Action>()
        let sut = HomeTabs(.testDependencies(), action: { parent.record($0) })

        await sut.send(.signOutButtonTapped)

        let actions = parent.values
        try #require(actions.count == 1)
        guard case .signOutButtonTapped = actions[0] else {
            Issue.record("親へ届いた Action が想定と違う: \(actions)")
            return
        }
    }
}
