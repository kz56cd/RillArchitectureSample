# 4 つの条件をどこで確かめるか

[README に戻る](../README.md)

## 1. 状態管理がアーキテクチャとして組み込まれている

- 画面の状態は、すべてストア(`Stores/`)の `State` の構造体にまとめ、`private(set) var state` で持つ。
  View は状態を持たない(`@State` はアプリの一番上の `AppRoot` だけ)。
- `Composable` が `State` と `state` を要件にしているので、どのストアも同じ形になる(`Packages/Rill/Sources/Rill/Composable.swift`)。
- 状態を変える入口は `send(Action)` の 1 つだけ。
- 遷移も状態として持つ。`AppRoot.State.screen`、`NewLog.State.phase`、`LogList.State.detail` に子のストアを入れれば出て、外せば消える。

```swift
@Observable
final class LogList: Composable {

    struct State {
        var logs: [ReadingLog] = []
        var detail: LogDetail?
        var loadFailed = false
    }

    private(set) var state: State
    ...
}
```

### 状態を見る(pretty print)

`store.prettyState` で、状態を字下げした文字列にできる。`store.printState()` はそれをコンソールに出す。
LLDB では `po store.prettyState` で見られる。

子のストアは、その `State` を入れ子で並べるので、一番上の `AppRoot` から出すとアプリ全体の状態が 1 つの木で見える。
集合と辞書は並べ替えて出すので、何度出しても同じ文字列になる(テストで丸ごと比べられる)。

```
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
          ReadingLog(...)
        ],
        detail: nil,
        loadFailed: false
      )
    )
  )
)
```

`print(store.state)` や `po store.state` の既定の出力(`CustomDebugStringConvertible`)を差し替える形にはしていない。
`debugDescription` は隔離されない要件なので、MainActor のストアの状態を読む実装と相性が悪いため。

## 2. テストしやすい

`make test` で 47 件(アプリのストア 22 件、Rill パッケージ 25 件)。
どれも View を立ち上げず、ストアを作って `await send(...)` し、状態を確かめるだけ。

アプリのストアのテスト(`RillArchitectureSampleTests`):

| テスト | 確かめること |
|---|---|
| `LogFormTests` | 1 つのストア。依存の差し替え(`testDependency(of:)`)、親へ届いた Action |
| `NewLogTests` | 親子。子へ `send` すると、親の状態が変わる |
| `HomeTabsTests` | 兄弟。記録する画面で保存すると、親が中継して一覧に足される |
| `LogListTests` | シートの子。子の「閉じる」「削除」で、親が閉じる |
| `AppRootTests` | ログイン → 記録 → 一覧 → ログアウトを、Action だけで通す。アプリ全体の状態を `prettyState` で丸ごと比べる |

Rill パッケージのテスト(`RillTests`)。アプリの型を使わず、テスト用の小さなストアで決まりそのものを確かめる:

| テスト | 確かめること |
|---|---|
| `ComposableTests` | `send` は `reduce` で状態を確定してから親へ伝える。`reduce` の中で待つ処理も終わりまで待つ。`reduce` の中から `send` すると結果が先に親へ届く。`reduce` を書かないストアは親へそのまま伝える |
| `PresentationTests` | `presentation` の Binding は子のストアを返す。`nil` を入れると dismiss の Action を送って閉じる。`nil` 以外を入れても何も送らない |
| `DependencyClientTests` | `testDependency` は差し替えた所だけを変え、`testValue` そのものは変えない |
| `PrettyPrinterTests` | 文字、数、`Optional`、構造体、列挙型(関連値つき)、配列、集合、辞書、入れ子のストアを、決まった形で字下げして出す |

`send` の順番を逆にすると、`ComposableTests` と `PresentationTests` の 5 件が落ちることを確かめてある。

`send` は `reduce` の終わりまで待つので、待ち合わせのコードは要らない。

## 3. 単一方向である

`make check-unidirectional` で確かめる。`Checks/UnidirectionalViolations.swift` の、外から状態を書き換える 9 行が、
すべて `setter is inaccessible` のコンパイルエラーになる。

決まり:

1. ストアの状態は `State` にまとめ、`private(set) var state` で持つ。`store.state.xxx = ...` は、そのストアの外からは書けない。
2. 例外は入力欄の値だけ。`TextField` は同期で書き換える必要があるため。
   `state` の中の値を、書き込みのできる計算プロパティ(`Login.userID`、`LogForm.draft`)として 1 つずつ出し、`$store.draft` で束縛する。
   `$store.state.draft` では束縛できない。値を使う判断(確かめる、保存する)は `send(.saveButtonTapped)` の中で行う。
3. 親から子への指示も `await child.send(...)` で行う(`HomeTabs` が `logList.send(.logAdded(...))` を呼ぶ)。
4. `reduce` の中で `Task { }` を作らない。

シートは `$store.state.detail` で束縛できない(決まり 1)。代わりに `store.presentation(\.state.detail, dismiss: .detailDismissed)`
(`Packages/Rill/Sources/Rill/Composable+Presentation.swift`)を使い、スワイプで閉じたときも Action を通す。

## 4. View 同士の連携がしやすい

| 連携 | 見本の場所 |
|---|---|
| 子から親 | `LogForm` の `saveResponse` → `NewLog.reduce` の `.form(.saveResponse(.success))` |
| 親から子 | `HomeTabs.reduce` が `logList.send(.logAdded(...))` |
| 兄弟の間 | 記録する画面(孫)で保存 → `HomeTabs` が受けて → 一覧へ送る |
| 子を出す、閉じる | `LogList.State.detail`(シート)。子の「閉じる」「削除」は親が受けて `nil` にする |
| 画面の切り替え | `AppRoot.State.screen`(ログイン ↔ タブ)、`NewLog.State.phase`(入力中 ↔ 保存したあと) |
