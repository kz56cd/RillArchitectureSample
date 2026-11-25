# 画面に出す文言(DisplayText)

[README に戻る](../README.md)

ストアの状態に、画面に出す文言を持つときは `String` ではなく `DisplayText` で持つ。
訳す文言(`LocalizedStringResource`)と、訳さずにそのまま出す文言(`String`)の両方を、1 つの型で扱える。

## 書き分け

書き分けは SwiftUI の `Text` と同じにしている。

| 書き方 | 扱い |
|---|---|
| `"削除できませんでした"`(文字列リテラル) | 訳す。リテラルがキーになる |
| `"「\(title)」を削除しますか?"`(埋め込みのあるリテラル) | 訳す。キーは `「%@」を削除しますか?`。埋め込んだ値は訳さない |
| `DisplayText(resource)`(`LocalizedStringResource`) | 訳す |
| `DisplayText(serverMessage)`(`String` の変数) | 訳さず、そのまま出す |

```swift
struct State {
    var title: DisplayText = "記録"                                // 訳す
    var notice: DisplayText?
}

state.notice = "「\(log.title)」を保存しました"                     // 訳す(本の名前は埋め込む)
state.notice = DisplayText(response.message)                        // サーバーの文言は、そのまま出す
```

訳が見つからなければキー(書いた文字列)をそのまま出す。`Localizable.xcstrings` が無いアプリでも、同じように使える。
多言語に対応すると決めたときに、書き方を変えずに訳を足せる。

## 出し方

| 場所 | 書き方 |
|---|---|
| SwiftUI | `Text(store.state.title)`。nil になりうる文言は `if let notice = store.state.notice { Text(notice) }` |
| UIKit、ログ | `store.state.title.resolve()`(今の言語の文字列にする)。`resolve(locale:)` で言語を指定できる |
| テスト | `#expect(state.notice == "「見本の本」を保存しました")` のように比べる。訳す文言どうし、そのまま出す文言どうしで比べる。埋め込みのある文言は `resolve()` で比べる |
| `prettyState` | 訳す文言はキー(`"削除できませんでした"`)、そのまま出す文言は `verbatim("...")` と出す。どの言語で動かしても同じ文字列になる |

文字列リテラルの `Text("...")` は、これまでどおり SwiftUI の書き方が選ばれる。`DisplayText` を足しても、今の View の書き方は変わらない。

## 補助が文言を受け取るとき

Rill の補助のうち、文言を受け取るのはアラートと確認ダイアログ(`AlertState`、`AlertButton`)。どちらも `DisplayText` で受け取る。
`String` の変数もそのまま渡せる(訳さずに出す)。

```swift
AlertState(title: "削除できませんでした")                         // 訳す
AlertState(title: serverMessage)                                  // そのまま出す
AlertState(title: "削除できませんでした", message: DisplayText(serverMessage))
AlertButton(bookTitle, action: .bookChosen(id))                   // そのまま出す
```

タイトルとメッセージの両方を渡すとき、メッセージに `String` の変数を渡すなら `DisplayText(...)` と書く。
メッセージだけ変数にしたときに、タイトルのリテラルまで「訳さない」扱いへ黙って変わらないようにするため(その書き方はコンパイルエラーになる)。

今後、文言を受け取る補助を足すときも、`DisplayText` で受け取る。

## 何が保証されるか

| 保証すること | 仕組み |
|---|---|
| 訳す文言とそのまま出す文言を取り違えない | 書き方で決まり、値にも残る(`.localized`、`.verbatim`)。テストで、同じ文字でも別の値になることを確かめている |
| サーバーの文言や利用者の入力が、たまたま訳のキーと同じでも訳されない | `String` の変数は `.verbatim` になり、訳を探さない。シミュレーターで、訳の表に同じキーがあっても訳されないことを確かめた |
| 状態の出力やテストが、動かす言語で変わらない | `prettyState` はキーを出す。テストはキーどうし、値どうしで比べる |

## テスト

| テスト | 確かめること |
|---|---|
| `DisplayTextTests`(Rill) | リテラルは訳し、埋め込みのあるリテラルは値をキーの外に出す。`String` の変数はそのまま出す。`LocalizedStringResource` は訳す。同じ文字でも、訳すものとそのまま出すものは別の値。`resolve()`。`Text` を作れる。`AlertState`、`AlertButton` の書き分け |
| `PrettyPrinterTests`(Rill) | 訳す文言はキーを、そのまま出す文言は `verbatim(...)` を出す |
| `LogDetailTests` | 確認ダイアログのタイトルに、本の名前を埋め込む |

シミュレーターでも、英語の訳を足して英語で起動し、次のことを確かめた(訳と UI テストはリポジトリに含めていない)。

- 本の名前を埋め込んだタイトルが、英語の訳に名前を埋めて出る(`Delete “見本の本”?`)。
- 訳す文言は訳される。
- `String` の変数から作った文言は、訳の表に同じキーがあっても訳されない。
