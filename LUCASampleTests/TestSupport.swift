import Foundation
@testable import LUCASample

/// テストの中で投げるエラー
struct TestError: Error {}

/// 親へ届いた Action や、依存が呼ばれた値を、順に溜める。
final class Recorder<Value> {

    // MARK: Properties

    private(set) var values: [Value] = []

    // MARK: Functions

    func record(_ value: Value) {
        values.append(value)
    }
}

nonisolated extension ReadingLog {
    static func fixture(
        id: UUID = UUID(),
        title: String = "見本の本",
        pages: Int = 120,
        rating: Int? = 4
    ) -> ReadingLog {
        ReadingLog(
            id: id,
            input: ReadingLogInput(title: title, pages: pages, rating: rating),
            loggedAt: .distantPast
        )
    }
}

extension NewLog {
    /// 入力中の子のストア。保存したあとなら nil
    var form: LogForm? {
        guard case let .editing(form) = state.phase else { return nil }
        return form
    }

    /// 保存したあとの記録。入力中なら nil
    var saved: ReadingLog? {
        guard case let .saved(log) = state.phase else { return nil }
        return log
    }
}

extension AppRoot {
    var login: Login? {
        guard case let .login(login) = state.screen else { return nil }
        return login
    }

    var homeTabs: HomeTabs? {
        guard case let .main(homeTabs) = state.screen else { return nil }
        return homeTabs
    }
}
