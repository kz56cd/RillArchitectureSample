import Testing
@testable import RillArchitectureSample

/// 兄弟の連携のテスト
///
/// 記録する画面(孫)で保存すると、親の HomeTabs が中継して、一覧の画面(兄弟)に記録が足されることを確かめる。
struct HomeTabsTests {

    @Test func send_記録する画面で保存_一覧に足される() async throws {
        let sut = HomeTabs(.testDependencies())
        let form = try #require(sut.state.newLog.form)
        form.draft = ReadingLogDraft(title: "見本の本", pages: "120", rating: "")

        await form.send(.saveButtonTapped)

        let saved = try #require(sut.state.newLog.saved)
        #expect(sut.state.logList.state.logs == [saved])
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

    @Test func send_tabSelected_タブを切り替える() async {
        let sut = HomeTabs(.testDependencies())

        await sut.send(.tabSelected(.logList))

        #expect(sut.state.selectedTab == .logList)
    }

    @Test func send_deepLinkOpened_logList_一覧のタブで積んだ画面を閉じる() async {
        let log = ReadingLog.fixture()
        let sut = HomeTabs(.testDependencies())
        await sut.state.logList.send(.logAdded(log))
        await sut.state.logList.send(.logTapped(log))
        await sut.state.logList.send(.filterButtonTapped)

        await sut.send(.deepLinkOpened(.logList))

        #expect(sut.state.selectedTab == .logList)
        #expect(sut.state.logList.state.path.isEmpty)
        #expect(sut.state.logList.state.filter == nil)
    }

    @Test func send_deepLinkOpened_newLog_記録するタブで新しく記録できる() async throws {
        let sut = HomeTabs(.testDependencies())
        let form = try #require(sut.state.newLog.form)
        form.draft = ReadingLogDraft(title: "見本の本", pages: "120", rating: "")
        await form.send(.saveButtonTapped)
        await sut.send(.tabSelected(.logList))

        await sut.send(.deepLinkOpened(.newLog))

        #expect(sut.state.selectedTab == .newLog)
        let newForm = try #require(sut.state.newLog.form)
        #expect(newForm !== form)
    }
}
