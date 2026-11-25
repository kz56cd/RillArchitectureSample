import Foundation
import Rill

/// ディープリンクの行き先
///
/// | URL | 行き先 |
/// |---|---|
/// | `rill-sample://new`、`https://example.com/new` | 記録する画面 |
/// | `rill-sample://logs`、`https://example.com/logs` | 一覧の画面 |
/// | `rill-sample://logs/<記録の ID>`、`https://example.com/logs/<記録の ID>` | 記録の詳しい画面 |
///
/// 見本で登録しているのはカスタム URL スキームだけ。ユニバーサルリンクは、Associated Domains を設定すると同じ行き先になる。
nonisolated enum AppLink: DeepLink, Equatable {
    case newLog
    case logList
    case log(id: ReadingLog.ID)

    // MARK: Static Properties

    static let scheme = "rill-sample"
    static let webHost = "example.com"

    // MARK: Initializers

    init?(url: URL) {
        let segments: [String]
        switch url.scheme {
        case Self.scheme:
            // `rill-sample://logs/<ID>` は、host が `logs`、path が `/<ID>` になる。
            segments = [url.host()].compactMap(\.self) + url.pathComponents.filter { $0 != "/" }
        case "https" where url.host() == Self.webHost:
            segments = url.pathComponents.filter { $0 != "/" }
        default:
            return nil
        }

        switch (segments.first, segments.count) {
        case ("new", 1):
            self = .newLog
        case ("logs", 1):
            self = .logList
        case ("logs", 2):
            guard let id = UUID(uuidString: segments[1]) else {
                return nil
            }
            self = .log(id: id)
        default:
            return nil
        }
    }
}
