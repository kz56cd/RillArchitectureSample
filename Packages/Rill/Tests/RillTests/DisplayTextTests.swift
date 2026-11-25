import Foundation
import SwiftUI
import Testing
@testable import Rill

/// 画面に出す文言(`DisplayText`)のテスト
///
/// 書き方によって、訳すかそのまま出すかが決まることを確かめる。
struct DisplayTextTests {

    // MARK: 書き分け

    @Test func 文字列リテラル_訳す() {
        let text: DisplayText = "削除できませんでした"

        guard case let .localized(resource) = text else {
            Issue.record("訳す文言になっていない: \(text)")
            return
        }
        #expect(resource.key == "削除できませんでした")
    }

    @Test func 埋め込みのある文字列リテラル_訳し_埋め込んだ値はキーの外に出す() {
        let title = "見本の本"
        let text: DisplayText = "「\(title)」を削除しますか?"

        guard case let .localized(resource) = text else {
            Issue.record("訳す文言になっていない: \(text)")
            return
        }
        #expect(resource.key == "「%@」を削除しますか?")
        // 訳が無ければ、キーに値を埋めて出す。
        #expect(text.resolve() == "「見本の本」を削除しますか?")
    }

    @Test func Stringの変数_訳さずにそのまま出す() {
        let serverMessage = "サーバーが混み合っています"

        #expect(DisplayText(serverMessage) == .verbatim("サーバーが混み合っています"))
        #expect(DisplayText(serverMessage[...]) == .verbatim("サーバーが混み合っています"))
    }

    @Test func LocalizedStringResource_訳す() {
        let resource: LocalizedStringResource = "削除できませんでした"

        #expect(DisplayText(resource) == .localized(resource))
        #expect(DisplayText(resource) == "削除できませんでした")
    }

    @Test func 同じ文字でも_訳すものとそのまま出すものは別の値() {
        #expect(DisplayText("削除できませんでした" as String) != "削除できませんでした")
    }

    // MARK: 文字列にする

    @Test func resolve_訳が無ければキーのまま_そのまま出す文言は変えない() {
        #expect(DisplayText("削除できませんでした").resolve() == "削除できませんでした")
        #expect(DisplayText("100%" as String).resolve() == "100%")
    }

    @Test func Text_どちらの文言からも作れる() {
        // 組めることを確かめる。文字列リテラルの Text("...") が、これまでどおり SwiftUI の書き方を選ぶことも含む。
        _ = Text(DisplayText("訳す"))
        _ = Text(DisplayText("そのまま" as String))
        _ = Text("SwiftUI のまま")
    }

    // MARK: アラート

    @Test func AlertState_リテラルは訳し_Stringの変数はそのまま出す() {
        let serverMessage = "サーバーが混み合っています"
        let bookTitle = "見本の本"

        let literal = AlertState<Counter.Action>(title: "削除できませんでした")
        let variable = AlertState<Counter.Action>(title: serverMessage)
        let mixed = AlertState<Counter.Action>(title: "削除できませんでした", message: DisplayText(serverMessage))
        let button = AlertButton<Counter.Action>(bookTitle)

        #expect(literal.title == "削除できませんでした")
        #expect(variable.title == .verbatim(serverMessage))
        #expect(mixed.title == "削除できませんでした")
        #expect(mixed.message == .verbatim(serverMessage))
        #expect(button.title == .verbatim(bookTitle))
        #expect(AlertButton<Counter.Action>("キャンセル").title == "キャンセル")
    }
}
