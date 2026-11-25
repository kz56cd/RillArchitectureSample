# 4 つの条件をどこで確かめるか

[README に戻る](../README.md)

## 1. 状態管理がアーキテクチャとして組み込まれている

- 画面の状態は、すべてストア(`Stores/`)の `State` の構造体にまとめ、`private(set) var state` で持つ。
  View は状態を持たない(`@State` はアプリの一番上の `AppRoot` だけ)。
- `Composable` が `State` と `state` を要件にしているので、どのストアも同じ形になる(`Packages/Rill/Sources/Rill/Composable.swift`)。
- 状態を変える入口は `send(Action)` の 1 つだけ。
- 遷移も状態として持つ。`AppRoot.State.screen`、`NewLog.State.phase`、`LogList.State.filter`(シート)に子のストアを入れれば出て、外せば消える。
  push も同じで、`LogList.State.path` に子のストアを積めば進み、取り除けば戻る。選んでいるタブも `HomeTabs.State.selectedTab` で持つ。
- ディープリンクも Action(`AppRoot.Action.deepLinkOpened`)で受け、各ストアが自分の状態を変える([ディープリンク](deeplink.md))。
- 通知も `AsyncStream` にして Action(`LogList.Action.appBecameActive`)で受ける([通知](notifications.md))。

```swift
@Observable
final class LogList: Composable {

    struct State {
        var logs: [ReadingLog] = []
        var loadFailed = false
        var minimumRating: Int?
        var path: [Destination] = []   // push で積んだ画面
        var filter: LogFilter?         // シート
    }

    private(set) var state: State
    ...
}
```

### 状態を見る(pretty print)

`store.prettyState` で、状態を字下げした文字列にできる。`store.printState()` はそれをコンソールに出す。
LLDB では `po store.prettyState` で見られる。

子のストアは、その `State` を入れ子で並べるので(push で積んだ画面も含む)、一番上の `AppRoot` から出すとアプリ全体の状態が 1 つの木で見える。
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
        loadFailed: false,
        minimumRating: nil,
        path: [
          .detail(
            LogDetail.State(
              log: ReadingLog(...),
              isDeleting: false,
              deleteFailed: false
            )
          )
        ],
        filter: nil
      )
    )
  )
)
```

`print(store.state)` や `po store.state` の既定の出力(`CustomDebugStringConvertible`)を差し替える形にはしていない。
`debugDescription` は隔離されない要件なので、MainActor のストアの状態を読む実装と相性が悪いため。

## 2. テストしやすい

`make test` で 73 件(アプリのストア 38 件、Rill パッケージ 35 件)。引数を変えて繰り返すテストは 1 件と数える。
どれも View を立ち上げず、ストアを作って `await send(...)` し、状態を確かめるだけ。

アプリのストアのテスト(`RillArchitectureSampleTests`):

| テスト | 確かめること |
|---|---|
| `LogFormTests` | 1 つのストア。依存の差し替え(`testDependency(of:)`)、親へ届いた Action |
| `NewLogTests` | 親子。子へ `send` すると、親の状態が変わる |
| `HomeTabsTests` | 兄弟。記録する画面で保存すると、親が中継して一覧に足される。タブの切り替えと、ディープリンクを子へ渡すこと |
| `LogListTests` | push とシートの子。記録を選ぶと積み、戻ると取り除く。子の「削除」で親が戻す。絞り込みのシートで選ぶと、親が絞り込んで閉じる。ディープリンクで記録の画面だけを積む。アプリが前面に来たら(通知)読み込み直し、画面が消えたら受けなくなる |
| `AppLinkTests` | ディープリンクの URL を行き先にする。解釈できない URL は nil |
| `AppRootTests` | ログイン → 記録 → 一覧 → ログアウトを、Action だけで通す。ディープリンクを、ログインの前後で受ける。積んだ画面も含めたアプリ全体の状態を `prettyState` で丸ごと比べる |

Rill パッケージのテスト(`RillTests`)。アプリの型を使わず、テスト用の小さなストアで決まりそのものを確かめる:

| テスト | 確かめること |
|---|---|
| `ComposableTests` | `send` は `reduce` で状態を確定してから親へ伝える。`reduce` の中で待つ処理も終わりまで待つ。`reduce` の中から `send` すると結果が先に親へ届く。`reduce` を書かないストアは親へそのまま伝える |
| `PresentationTests` | `presentation` の Binding は子のストアを返す。`nil` を入れると dismiss の Action を送って閉じる。`nil` 以外を入れても何も送らない |
| `NavigationTests` | `navigationPath` の Binding は積んだ子のストアを返す。短くすると、残った数で pop の Action を送って戻る。長くしても何も送らない。`IdentityHashable` は同じストアだけを等しいとみなし、状態が変わってもハッシュ値は変わらない |
| `DeepLinkTests` | `open` は解釈できる URL だけを Action にして送る。`binding` は書き込むと Action を送り、`reduce` が状態を変える |
| `NotificationClientTests` | 通知を届いた順に値にして流す。受けているタスクを取り消すと受け取りを止める。`testValue` は何も届かない |
| `DependencyClientTests` | `testDependency` は差し替えた所だけを変え、`testValue` そのものは変えない |
| `PrettyPrinterTests` | 文字、数、`Optional`、構造体、列挙型(関連値つき)、配列、集合、辞書、入れ子のストア(積んだストアを含む)を、決まった形で字下げして出す |

`send` の順番を逆にすると、`ComposableTests`、`PresentationTests`、`NavigationTests`、`DeepLinkTests` の 8 件が落ちることを確かめてある。

`send` は `reduce` の終わりまで待つので、待ち合わせのコードは要らない。

## 3. 単一方向である

`make check-unidirectional` で確かめる。`Checks/UnidirectionalViolations.swift` の、外から状態を書き換える 15 行が、
すべて `setter is inaccessible` のコンパイルエラーになる。

決まり:

1. ストアの状態は `State` にまとめ、`private(set) var state` で持つ。`store.state.xxx = ...` は、そのストアの外からは書けない。
2. 例外は入力欄の値だけ。`TextField` は同期で書き換える必要があるため。
   `state` の中の値を、書き込みのできる計算プロパティ(`Login.userID`、`LogForm.draft`)として 1 つずつ出し、`$store.draft` で束縛する。
   `$store.state.draft` では束縛できない。値を使う判断(確かめる、保存する)は `send(.saveButtonTapped)` の中で行う。
3. 親から子への指示も `await child.send(...)` で行う(`HomeTabs` が `logList.send(.logAdded(...))` を呼ぶ)。
4. `reduce` の中で `Task { }` を作らない。

画面の遷移も、SwiftUI に状態を直接書き換えさせない(決まり 1)。

- シートは `$store.state.filter` で束縛できない。代わりに `store.presentation(\.state.filter, dismiss: .filterDismissed)`
  (`Packages/Rill/Sources/Rill/Composable+Presentation.swift`)を使い、スワイプで閉じたときも Action を通す。
- push は `NavigationStack(path: $store.state.path)` で束縛できない。代わりに
  `store.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })`(`Packages/Rill/Sources/Rill/Composable+Navigation.swift`)を使い、
  戻るボタンや端からのスワイプで戻ったときも、残った画面の数を Action で送る。
  積むのは `reduce` の中だけ。`NavigationLink(value:)` は使わず、ボタンで Action を送る(SwiftUI が足そうとしても無視する)。
- タブは `TabView(selection: $store.state.selectedTab)` で束縛できない。代わりに
  `store.binding(\.state.selectedTab, send: { .tabSelected($0) })`(`Packages/Rill/Sources/Rill/Composable+Binding.swift`)を使う。
  `Picker` や `Toggle` など、選ぶ操作も同じ。入力欄は決まり 2 の例外のままで、`binding` は使わない。
- ディープリンクで行き先の画面の状態を直接作れない。一番上のストアへ `.deepLinkOpened` を送る。
- `NavigationStack` の path の要素は `Hashable` でなければならない。ストアは `IdentityHashable` に準拠させ、同じストアかどうかで比べる。
  モジュールの既定の隔離が MainActor なので、`final class LogDetail: Composable, nonisolated IdentityHashable` と `nonisolated` を付ける
  (付けないと `Hashable` への準拠が MainActor に隔離され、コンパイルエラーになる)。

## 4. View 同士の連携がしやすい

| 連携 | 見本の場所 |
|---|---|
| 子から親 | `LogForm` の `saveResponse` → `NewLog.reduce` の `.form(.saveResponse(.success))` |
| 親から子 | `HomeTabs.reduce` が `logList.send(.logAdded(...))` |
| 兄弟の間 | 記録する画面(孫)で保存 → `HomeTabs` が受けて → 一覧へ送る |
| 子を積む、戻る(push) | `LogList.State.path`。記録を選ぶと `LogDetail` を積む。子の「削除」は親が受けて取り除く |
| 子を出す、閉じる(シート) | `LogList.State.filter`。子の「評価を選ぶ」「キャンセル」は親が受けて `nil` にする |
| 画面の切り替え | `AppRoot.State.screen`(ログイン ↔ タブ)、`HomeTabs.State.selectedTab`(タブ)、`NewLog.State.phase`(入力中 ↔ 保存したあと) |
| 外からの出来事(通知) | `LogList` が、アプリが前面に来たら読み込み直す。画面どうしの連携には使わない |
| ディープリンク | `AppRoot` が受け、`HomeTabs` がタブを選び、`LogList` が記録の画面を積む。ログインする前なら覚えておく |
