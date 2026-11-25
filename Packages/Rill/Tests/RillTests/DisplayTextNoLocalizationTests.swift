// 多言語化しないアプリ(trait `NoLocalization` を有効にしたとき)の `DisplayText`。
// `swift test --traits NoLocalization` で流す。
#if NoLocalization

import SwiftUI
import Testing
@testable import Rill

/// 多言語化しないアプリでは、`DisplayText` が `String` そのものであることを確かめる。
struct DisplayTextNoLocalizationTests {

    @Test func DisplayTextはStringそのもの() {
        #expect(DisplayText.self == String.self)
    }

    @Test func Stringと同じように使える() {
        let name = "見本の本"
        var text: DisplayText = "「\(name)」を保存しました"

        // 変数をそのまま入れられ、文字列として数えたり、つなげたりできる。
        text = name
        text += "(2 冊目)"
        #expect(text.count == 10)
        #expect(text == "見本の本(2 冊目)")
        #expect(text.contains("見本"))
    }

    @Test func AlertState_リテラルと変数を混ぜて渡せる() {
        let serverMessage = "サーバーが混み合っています"
        let bookTitle = "見本の本"

        // 多言語化するアプリでは DisplayText(serverMessage) と書く必要があるが、ここではそのまま渡せる。
        let alert = AlertState<Counter.Action>(title: "削除できませんでした", message: serverMessage)
        let button = AlertButton<Counter.Action>(bookTitle)

        #expect(alert.title == "削除できませんでした")
        #expect(alert.message == serverMessage)
        #expect(button.title == bookTitle)
    }

    @Test func Text_SwiftUIのTextがそのまま使える() {
        let text: DisplayText = "削除できませんでした"
        _ = Text(text)
        _ = Text("SwiftUI のまま")
    }
}

#endif
