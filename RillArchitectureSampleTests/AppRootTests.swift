import Rill
import Foundation
@testable import RillArchitectureSample
import Testing

/// アプリの一番上のストアのテスト
///
/// ログイン → 記録の保存 → 一覧への反映 → ログアウトまで、Action だけで通して確かめる。
struct AppRootTests {

    @Test func send_ログインできた_タブの画面へ切り替わる() async throws {
        let sut = AppRoot(.testDependencies())
        let login = try #require(sut.login)
        login.userID = "user"

        await login.send(.loginButtonTapped)

        #expect(sut.homeTabs != nil)
    }

    @Test func send_ログインに失敗_ログインの画面のまま() async throws {
        let authClient = testDependency(of: AuthClient.self) {
            $0.signIn = { _ in throw TestError() }
        }
        let sut = AppRoot(.testDependencies(authClient: authClient))
        let login = try #require(sut.login)
        login.userID = "user"

        await login.send(.loginButtonTapped)

        #expect(sut.login === login)
        #expect(login.state.errorMessage == "ログインできませんでした")
    }

    @Test func send_ユーザーIDが空_ログインしない() async throws {
        let called = Recorder<String>()
        let authClient = testDependency(of: AuthClient.self) {
            $0.signIn = { await called.record($0) }
        }
        let sut = AppRoot(.testDependencies(authClient: authClient))
        let login = try #require(sut.login)
        login.userID = "  "

        await login.send(.loginButtonTapped)

        #expect(called.values.isEmpty)
        #expect(sut.login === login)
        #expect(login.state.errorMessage == "ユーザー ID を入力してください")
    }

    @Test func send_ログインから記録とログアウトまで通す() async throws {
        let sut = AppRoot(.testDependencies())
        let login = try #require(sut.login)
        login.userID = "user"
        await login.send(.loginButtonTapped)
        let homeTabs = try #require(sut.homeTabs)

        let form = try #require(homeTabs.state.newLog.form)
        form.draft = ReadingLogDraft(title: "見本の本", pages: "120", rating: "")
        await form.send(.saveButtonTapped)
        #expect(homeTabs.state.logList.state.logs.count == 1)

        await homeTabs.send(.signOutButtonTapped)
        let newLogin = try #require(sut.login)
        #expect(newLogin !== login)
        #expect(newLogin.userID.isEmpty)
    }

    @Test func prettyState_アプリ全体の状態を1つの木で出す() async throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let readingLogClient = testDependency(of: ReadingLogClient.self) {
            $0.save = { ReadingLog(id: id, input: $0, loggedAt: .distantPast) }
        }
        let sut = AppRoot(.testDependencies(readingLogClient: readingLogClient))
        let login = try #require(sut.login)
        login.userID = "user"
        await login.send(.loginButtonTapped)
        let form = try #require(sut.homeTabs?.state.newLog.form)
        form.draft = ReadingLogDraft(title: "見本の本", pages: "120", rating: "")

        await form.send(.saveButtonTapped)

        #expect(sut.prettyState == """
            AppRoot.State(
              screen: .main(
                HomeTabs.State(
                  newLog: NewLog.State(
                    phase: .saved(
                      ReadingLog(
                        id: 00000000-0000-0000-0000-000000000001,
                        title: "見本の本",
                        pages: 120,
                        rating: nil,
                        loggedAt: 0001-01-01 00:00:00 +0000
                      )
                    )
                  ),
                  logList: LogList.State(
                    logs: [
                      ReadingLog(
                        id: 00000000-0000-0000-0000-000000000001,
                        title: "見本の本",
                        pages: 120,
                        rating: nil,
                        loggedAt: 0001-01-01 00:00:00 +0000
                      )
                    ],
                    detail: nil,
                    loadFailed: false
                  )
                )
              )
            )
            """)
    }
}
