import Foundation
@testable import RillArchitectureSample
import Testing

/// ディープリンクの URL の解釈のテスト
struct AppLinkTests {

    nonisolated private static let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    @Test(arguments: [
        ("rill-sample://new", AppLink.newLog),
        ("rill-sample://logs", AppLink.logList),
        ("rill-sample://logs/00000000-0000-0000-0000-000000000001", AppLink.log(id: id)),
        ("https://example.com/new", AppLink.newLog),
        ("https://example.com/logs", AppLink.logList),
        ("https://example.com/logs/00000000-0000-0000-0000-000000000001", AppLink.log(id: id))
    ])
    func init_行き先にする(string: String, expected: AppLink) throws {
        let url = try #require(URL(string: string))

        #expect(AppLink(url: url) == expected)
    }

    @Test(arguments: [
        "rill-sample://logs/not-an-id",
        "rill-sample://unknown",
        "rill-sample://logs/00000000-0000-0000-0000-000000000001/extra",
        "other://logs",
        "https://other.example.com/logs",
        "http://example.com/logs"
    ])
    func init_解釈できない_nil(string: String) throws {
        let url = try #require(URL(string: string))

        #expect(AppLink(url: url) == nil)
    }
}
