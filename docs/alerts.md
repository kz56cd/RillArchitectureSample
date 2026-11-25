# アラートと確認ダイアログ

[README に戻る](../README.md)

アラートと確認ダイアログも、ほかの画面と同じく状態から出す。中身(タイトル、メッセージ、ボタンと押したときの Action)を
値の型 `AlertState` でストアの状態に持ち、閉じるのも押したボタンも Action として受ける。

## 書き方

```swift
// ストアの状態
struct State {
    var confirmation: AlertState<Action>?   // 確認ダイアログ
    var alert: AlertState<Action>?          // アラート
}

// reduce
case .deleteButtonTapped:
    state.confirmation = AlertState(
        title: "この記録を削除しますか?",
        message: "削除すると、元に戻せません。",
        buttons: [
            AlertButton("削除する", role: .destructive, action: .deleteConfirmed),
            AlertButton("キャンセル", role: .cancel)   // Action が無いボタンは、閉じるだけ
        ]
    )

case .confirmationDismissed:
    state.confirmation = nil

case .deleteConfirmed:
    // 削除する

case .deleteResponse(.failure):
    state.alert = AlertState(title: "削除できませんでした", message: "時間をおいて、もう一度お試しください。")

case .alertDismissed:
    state.alert = nil
```

```swift
// View
.confirmationDialog(store: store, state: \.state.confirmation, dismiss: .confirmationDismissed)
.alert(store: store, state: \.state.alert, dismiss: .alertDismissed)
```

ボタンを書かなければ、閉じるだけの「OK」が出る。

## ボタン

ボタンの数に決まりは無い。0 個(閉じるだけの「OK」)から何個でも並べられ、ボタンごとに別の Action を送れる。
Action は関連値を持てるので、`AlertButton("3 つ", action: .ratingChosen(3))` のように値を付けて送れる。

| 役割 | SwiftUI | 使う場面 |
|---|---|---|
| なし | ふつうのボタン | 選択肢の 1 つ |
| `.cancel` | `ButtonRole.cancel` | やめる |
| `.destructive` | `ButtonRole.destructive` | 消すなど、元に戻せないこと |
| `.confirm` | `ButtonRole.confirm`(iOS 26 から) | 決める |
| `.close` | `ButtonRole.close`(iOS 26 から) | 閉じる |

役割は SwiftUI の `ButtonRole` を直接持たず、自前の型で持つ。UIKit の `UIAlertAction.Style` にも読み替えられるようにするため。

## 文言

タイトル、メッセージ、ボタンの文言は `String` で持ち、そのまま出す。テストでは `alert.title == "削除できませんでした"` のように比べる。

今の Rill は、多言語化に対応していない。String Catalog を前提にした多言語化は [#9](https://github.com/kz56cd/RillArchitectureSample/issues/9) で扱う。

## 扱わないもの

アーキテクチャを膨らませないため、次のものは `AlertState` に入れていない。

| 扱わないもの | 代わりにすること |
|---|---|
| アラートの中の入力欄(`TextField`、`SecureField`) | 入力が要るものはシートで出す。入力欄の値は、決まり 2 の例外のとおりストアの計算プロパティで束縛する |
| ボタンを押せなくする(`.disabled`) | 入力欄と組み合わせて使うものなので、同じくシートで出す |
| 文字以外のボタン(アイコンなど)、確認ダイアログのタイトルを隠す | 必要になったら足す |

## 閉じるときの決まり

| 閉じ方 | 届く Action |
|---|---|
| Action のあるボタンを押す | 閉じる Action(`dismiss`)→ ボタンの Action |
| Action の無いボタン(キャンセル、OK)を押す | 閉じる Action だけ |
| 外を押す(確認ダイアログ) | 閉じる Action だけ |

- 閉じる Action は、どの閉じ方でも**ちょうど 1 回**届く。受けた `reduce` は、状態を nil にする。
- ボタンの Action は、閉じる Action の**あと**に届く。ボタンの Action を受けたときには、もう閉じた状態になっているので、
  続けて別のアラートを出してもよい。

SwiftUI は、ボタンを押したときに「ボタンの処理」と「出ていない(`isPresented = false`)への書き換え」の両方を呼ぶ。
どちらが先に呼ばれても、閉じる Action を送るのは「まだ出ている」ときの 1 回だけにしている。

iOS 26 の iPhone では、確認ダイアログは押したボタンの近くに吹き出しで出て、キャンセルのボタンは表示されない(外を押して閉じる)。
どの閉じ方でも閉じる Action が届くので、ストアの書き方は変わらない。

## 何がアーキテクチャで保証されるか

| 保証すること | 仕組み |
|---|---|
| View が状態を直接書き換えない | 出ているかどうかは状態(`private(set)`)にある。`make check-unidirectional` で、`confirmation`、`alert` を外から書く行がコンパイルエラーになることを確かめている |
| 閉じたのに状態が残らない | どの閉じ方でも閉じる Action が届く。残ると、次に出せなくなったり、出直したりする |
| 閉じる Action が二重に届かない | まだ出ているときだけ送る。順番を入れ替えたテストで確かめている |
| View を立ち上げずに確かめられる | 中身が値なので、出したか、どのボタンがあり、押すと何が送られるかを、ストアのテストで確かめられる |

## Rill パッケージの補助

| 補助 | すること |
|---|---|
| `AlertState`、`AlertButton` | アラートと確認ダイアログの中身。ボタンの役割(`.cancel`、`.destructive`)は SwiftUI にも UIKit にも読み替えられる自前の型で持つ |
| `View.alert(store:state:dismiss:)` | アラートとして出す |
| `View.confirmationDialog(store:state:dismiss:)` | 確認ダイアログとして出す |

## テスト

| テスト | 確かめること |
|---|---|
| `AlertTests`(Rill) | ボタンを押すと、閉じる Action のあとにボタンの Action を送る。Action の無いボタンは閉じるだけ。外を押すと閉じる Action を送る。ボタンと書き換えの順番によらず、閉じる Action は 1 回。役割を SwiftUI の役割に読み替える |
| `PrettyPrinterTests`(Rill) | `AlertState` の文言を出す |
| `LogDetailTests` | 「削除する」で確認ダイアログを出し、確かめるまでは消さない。確認で削除する。キャンセルは消さずに閉じる。削除に失敗したらアラートを出し、閉じると消える |

「まだ出ているときだけ送る」確かめを外すと、`AlertTests` の順番を入れ替えたテストが両方落ちることを確かめてある。

シミュレーターでも、UI テストで次のことを確かめた(この UI テストはリポジトリに含めていない)。

- 確認ダイアログで「削除する」を押すと、削除して一覧へ戻る。
- 外を押して閉じると、出直さず、もう一度押せば出る(2 回続けて確かめた)。
- 削除に失敗するとアラートが出て、OK で閉じると出直さず、もう一度確認から始められる。
- `.close` の役割のボタンも出る(確かめるためだけに足したもので、見本には入れていない)。

## UIKit で使うとき

`updateProperties()` で `state.alert` を見て、`UIAlertController` を出し入れする。

- ボタンは `UIAlertAction` にする。役割は `.cancel` → `.cancel`、`.destructive` → `.destructive`、それ以外(なし、`.confirm`、`.close`)→ `.default`。
  `.confirm` のボタンは `UIAlertController.preferredAction` にすると、意図が近くなる。
- 文言は `alert.title` をそのまま使う。
- ボタンの処理では、閉じる Action を送ってから、ボタンの Action を送る。
- 確認ダイアログは `preferredStyle: .actionSheet` にする。外を押して閉じたときは `.cancel` のボタンの処理が呼ばれる作りなので、`.cancel` のボタンが無ければ足し、その処理で閉じる Action を送る。

UIKit の部分は考え方だけで、コードは型検査も動作も確かめていない。
