import Foundation
import Testing
@testable import Rill

/// `PrettyPrinter` と `prettyState` のテスト
struct PrettyPrinterTests {

    struct Book {
        var title: String
        var pages: Int
        var rating: Int?
    }

    struct Empty {}

    enum Phase {
        case idle
        case loaded(Book)
        case failed(code: Int, retry: Bool)
    }

    // MARK: 値

    @Test func format_文字や数_1行で出す() {
        #expect(PrettyPrinter.format(42) == "42")
        #expect(PrettyPrinter.format(true) == "true")
        #expect(PrettyPrinter.format("見本\n\"本\"") == #""見本\n\"本\"""#)
    }

    @Test func format_Optional_nilか中身を出す() {
        let none: Int? = nil
        let some: Int? = 3
        #expect(PrettyPrinter.format(none as Any) == "nil")
        #expect(PrettyPrinter.format(some as Any) == "3")
    }

    @Test func format_UUIDと日付_そのまま出す() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        #expect(PrettyPrinter.format(id) == "00000000-0000-0000-0000-000000000001")
        #expect(PrettyPrinter.format(Date(timeIntervalSince1970: 0)) == "1970-01-01 00:00:00 +0000")
    }

    // MARK: 構造体

    @Test func format_構造体_項目を1行ずつ字下げして出す() {
        let book = Book(title: "見本の本", pages: 120, rating: nil)

        #expect(PrettyPrinter.format(book) == """
            PrettyPrinterTests.Book(
              title: "見本の本",
              pages: 120,
              rating: nil
            )
            """)
    }

    @Test func format_項目の無い構造体_1行で閉じる() {
        #expect(PrettyPrinter.format(Empty()) == "PrettyPrinterTests.Empty()")
    }

    // MARK: 列挙型

    @Test func format_関連値の無いcase_名前だけを出す() {
        #expect(PrettyPrinter.format(Phase.idle) == ".idle")
    }

    @Test func format_関連値が1行で収まる_1行で出す() {
        #expect(PrettyPrinter.format(Phase.failed(code: 404, retry: true)) == ".failed(code: 404, retry: true)")
    }

    @Test func format_関連値が複数行_字下げして出す() {
        let phase = Phase.loaded(Book(title: "見本の本", pages: 120, rating: 4))

        #expect(PrettyPrinter.format(phase) == """
            .loaded(
              PrettyPrinterTests.Book(
                title: "見本の本",
                pages: 120,
                rating: 4
              )
            )
            """)
    }

    // MARK: コレクション

    @Test func format_配列_要素を1行ずつ出す() {
        #expect(PrettyPrinter.format([Int]()) == "[]")
        #expect(PrettyPrinter.format([1, 2]) == """
            [
              1,
              2
            ]
            """)
    }

    @Test func format_集合_並べ替えて出す() {
        let set: Set<String> = ["c", "a", "b"]

        #expect(PrettyPrinter.format(set) == """
            Set([
              "a",
              "b",
              "c"
            ])
            """)
    }

    @Test func format_辞書_キーで並べ替えて出す() {
        let dictionary = ["b": 2, "a": 1]

        #expect(PrettyPrinter.format([String: Int]()) == "[:]")
        #expect(PrettyPrinter.format(dictionary) == """
            [
              "a": 1,
              "b": 2
            ]
            """)
    }

    @Test func format_LocalizedStringResource_キーだけを出す() {
        let resource: LocalizedStringResource = "削除できませんでした"

        #expect(PrettyPrinter.format(resource) == "\"削除できませんでした\"")
    }

    #if !NoLocalization
    @Test func format_DisplayText_訳す文言はキーを_そのまま出す文言はverbatimで出す() {
        #expect(PrettyPrinter.format(DisplayText("削除できませんでした")) == "\"削除できませんでした\"")
        #expect(PrettyPrinter.format(DisplayText("混み合っています" as String)) == "verbatim(\"混み合っています\")")
    }
    #else
    @Test func format_DisplayText_Stringと同じに出す() {
        let text: DisplayText = "削除できませんでした"

        #expect(PrettyPrinter.format(text) == "\"削除できませんでした\"")
    }
    #endif

    @Test func format_AlertState_文言はキーで出す() {
        let alert = AlertState<Counter.Action>(
            title: "数を 0 に戻しますか?",
            buttons: [AlertButton("戻す", role: .destructive, action: .resetConfirmed)]
        )

        #expect(PrettyPrinter.format(alert) == """
            AlertState<Counter.Action>(
              title: "数を 0 に戻しますか?",
              message: nil,
              buttons: [
                AlertButton<Counter.Action>(
                  title: "戻す",
                  role: .destructive,
                  action: .resetConfirmed
                )
              ]
            )
            """)
    }

    // MARK: ストア

    @Test func prettyState_子と積んだストアの状態も入れ子で出す() async {
        let sut = Counter(state: .init(count: 1))
        await sut.send(.openChildButtonTapped)
        await sut.send(.pushButtonTapped)

        #expect(sut.prettyState == """
            Counter.State(
              count: 1,
              child: Counter.State(
                count: 0,
                child: nil,
                path: [],
                alert: nil
              ),
              path: [
                Counter.State(
                  count: 0,
                  child: nil,
                  path: [],
                  alert: nil
                )
              ],
              alert: nil
            )
            """)
    }

    @Test func prettyState_状態が変わると出す内容も変わる() async {
        let sut = Counter()
        let before = sut.prettyState

        await sut.send(.incrementButtonTapped)

        #expect(before != sut.prettyState)
        #expect(sut.prettyState.contains("count: 1"))
    }
}
