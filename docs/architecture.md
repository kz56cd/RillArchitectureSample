# 構造の図

[README に戻る](../README.md)

## 層と依存の向き

矢印は「使う」向き。View はストアだけを、ストアは依存だけを知る。
ストアと依存の決まり(`Composable`、`DependencyClient`)は、アプリから切り離した `Rill` パッケージに置く。
パッケージはアプリの型を知らない。

```mermaid
flowchart TB
    subgraph App["アプリ(RillArchitectureSample)"]
        subgraph Views["Views(SwiftUI)"]
            V["LoginView / NewLogView / LogListView ..."]
        end
        subgraph Stores["Stores(@Observable + Composable)"]
            S["AppRoot / HomeTabs / NewLog / LogList ..."]
        end
        subgraph Dependencies["Dependencies(DependencyClient)"]
            D["AppDependencies<br/>AuthClient / ReadingLogClient"]
        end
        subgraph Models["Models(値の型)"]
            M["ReadingLog / ReadingLogDraft"]
        end
    end
    subgraph Package["Rill パッケージ"]
        P["Composable / DependencyClient / PrettyPrinter<br/>testDependency / presentation"]
    end
    Live["liveValue<br/>(本番。見本ではメモリの保存先)"]
    Test["testValue<br/>(テストで差し替える)"]

    V -- "send(Action)、状態を読む" --> S
    S -- "init で受け取って呼ぶ" --> D
    D --- Live
    D --- Test
    V & S & D -.-> M
    S -- "準拠する" --> P
    D -- "準拠する" --> P
    V -- "presentation を使う" --> P
```

## 1 つの画面の中の流れ(単一方向)

状態を書き換えられるのは `reduce` だけ。View は Action を送り、状態の変化を Observation で受け取って描き直す。

```mermaid
flowchart LR
    View["View"] -- "send(Action)" --> Reduce["reduce(Action)"]
    Reduce -- "書き換える" --> State[("State<br/>private(set) var state")]
    State -- "Observation で描き直す" --> View
    Reduce -- "呼ぶ" --> Dep["DependencyClient"]
    Dep -- "結果" --> Reduce
    Reduce -- "send(.xxxResponse)" --> Reduce
    Reduce -- "action(Action)" --> Parent["親のストア"]
    View -. "例外:入力欄だけ直接束縛" .-> Draft[("store.draft / store.userID")]
```

## 画面とストアの木

実線は「親が子のストアを持つ」。子の Action は `action` のクロージャで親の `reduce` に届き、親は子へ `send` で指示する。

```mermaid
flowchart TD
    App["RillArchitectureSampleApp<br/>@State で AppRoot を持つ"] --> AppRoot
    AppRoot["AppRoot<br/>ログインの状態で出し分ける"]
    AppRoot -- "screen = .login" --> Login["Login<br/>ログインする前"]
    AppRoot -- "screen = .main" --> HomeTabs["HomeTabs<br/>兄弟の連携を中継する"]
    HomeTabs -- "newLog" --> NewLog["NewLog<br/>入力中と保存したあとを出し分ける"]
    HomeTabs -- "logList" --> LogList["LogList<br/>記録の一覧"]
    NewLog -- "phase = .editing" --> LogForm["LogForm<br/>入力欄と保存"]
    LogList -- "detail(シート)" --> LogDetail["LogDetail<br/>記録の詳しい画面"]
```

## 親子の間のやり取り

上へは `action` のクロージャ、下へは `send`。どちらも Action で、相手の状態には触らない。

```mermaid
flowchart TB
    subgraph Parent["親(NewLog)"]
        direction LR
        PR["reduce"] -- "書き換える" --> PS[("phase")]
    end
    subgraph Child["子(LogForm)"]
        direction LR
        CR["reduce"] -- "書き換える" --> CS[("draft / invalidFields ...")]
    end
    PR -- "child.send(Action)" --> CR
    CR -- "action(Action)<br/>.form(Action) として届く" --> PR
```

子を作るときに、親が `action` を渡す。

```swift
LogForm(appDependencies, action: { [weak self] in await self?.send(.form($0)) })
```

## 兄弟の連携:記録を保存すると一覧に足される

記録する画面(孫)の結果が、親の `HomeTabs` で中継されて、一覧の画面(兄弟)へ届く。

```mermaid
sequenceDiagram
    actor User as 利用者
    participant V as LogFormView
    participant F as LogForm
    participant C as ReadingLogClient
    participant N as NewLog
    participant T as HomeTabs
    participant L as LogList

    User->>V: 「保存する」を押す
    V->>F: send(.saveButtonTapped)
    F->>F: reduce: draft を確かめる
    F->>C: save(input)
    C-->>F: 保存した記録
    F->>F: send(.saveResponse(.success)) → reduce: isSaving = false
    F->>N: action(.saveResponse(.success))
    N->>N: reduce: phase = .saved(記録)
    N->>T: action(.form(.saveResponse(.success)))
    T->>L: send(.logAdded(記録))
    L->>L: reduce: logs の先頭に足す
    Note over F,T: このあと .saveButtonTapped も、同じ道筋で親へ届く(結果が先、押した操作があと)
```

## シートを閉じる:スワイプでも Action を通す

```mermaid
sequenceDiagram
    participant S as SwiftUI の .sheet
    participant B as presentation の Binding
    participant L as LogList

    S->>B: 下へのスワイプで set(nil)
    B->>L: Task { send(.detailDismissed) }
    L->>L: reduce: detail = nil
    L-->>S: Observation で描き直す
```

「閉じる」ボタンのときは、子(`LogDetail`)が `send(.closeButtonTapped)` し、親の `LogList` が `.detail(.closeButtonTapped)` として受けて `detail = nil` にする。
