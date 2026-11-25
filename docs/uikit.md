# UIKit で使う

[README に戻る](../README.md)

使える。ストア、依存、テストは UI の仕組みに依存しないので、そのまま使える。変わるのは View の層だけ。
(`Rill` パッケージで SwiftUI を使っているのは、画面の遷移の Binding の補助の `presentation`、`navigationPath`、`binding`、`onDeepLink` だけ。)

見本には UIKit の画面を含めていない。下のコードは、アプリのソースと一緒に型検査が通ることだけを確かめた概要で、動かしてはいない。

## SwiftUI との対応

| すること | SwiftUI | UIKit |
|---|---|---|
| 状態を読んで描く | `body` で `store.state` を読む | `updateProperties()` で `store.state` を読む。iOS 26 の UIKit は、そこで読んだ Observable の値を追い、変わると呼び直す |
| 操作を送る | `Button { Task { await store.send(...) } }` | `UIAction { _ in Task { await store.send(...) } }` |
| 入力欄(例外) | `$store.draft.title` で束縛する | `.editingChanged` で `store.draft.title = text` を同期で書く |
| 子の画面 | 子の View に子のストアを渡す | 子の ViewController に子のストアを渡す |
| push | `NavigationStack(path: store.navigationPath(\.state.path, pop: { .pathPopped(count: $0) }))` | `updateProperties()` で `state.path` と表示中の ViewController の並びを比べ、違えば `setViewControllers` する。戻るボタンやスワイプで戻ったら、`UINavigationControllerDelegate` の `didShow` で `.pathPopped(count:)` を送る |
| シート | `.sheet(item: store.presentation(\.state.filter, dismiss: .filterDismissed))` | `updateProperties()` で `state.filter` を見て `present` / `dismiss` する。スワイプで閉じたら `presentationControllerDidDismiss` で `.filterDismissed` を送る |
| タブ | `TabView(selection: store.binding(\.state.selectedTab, send: { .tabSelected($0) }))` | `UITabBarController`。`tabBarController(_:shouldSelect:)` で `false` を返して `.tabSelected` を送り、`updateProperties()` で `selectedIndex` を合わせる |
| 画面の切り替え | `switch store.state.screen` | `AppRoot.state.screen` を見て `rootViewController` を差し替える |
| 通知 | `.task { await store.send(.observeNotifications) }` | 受け取りの `Task` を ViewController が持ち、`viewDidAppear` で始めて `viewDidDisappear` で取り消す |
| ディープリンク | `.onDeepLink(AppLink.self, to: store) { .deepLinkOpened($0) }` | `scene(_:openURLContexts:)` と `scene(_:continue:)` で URL を受け、`store.open(url, as: AppLink.self) { .deepLinkOpened($0) }` を呼ぶ |

## 書き方の例

```swift
final class LogFormViewController: UIViewController {

    private let store: LogForm
    private let titleField = UITextField()
    private let saveButton = UIButton(configuration: .filled())
    private let errorLabel = UILabel()

    // init(store:) は省略

    override func viewDidLoad() {
        super.viewDidLoad()
        // 入力欄の値だけは、例外として同期で書き込む。
        titleField.addAction(UIAction { [unowned self] _ in
            store.draft.title = titleField.text ?? ""
        }, for: .editingChanged)
        // 操作は Action として送る。
        saveButton.addAction(UIAction { [unowned self] _ in
            Task { await store.send(.saveButtonTapped) }
        }, for: .primaryActionTriggered)
    }

    // iOS 26 の UIKit は、ここで読んだ Observable の値を追い、変わると呼び直す。
    override func updateProperties() {
        super.updateProperties()
        saveButton.isEnabled = !store.state.isSaving
        errorLabel.isHidden = store.state.invalidFields.isEmpty
    }
}

final class LogListViewController: UIViewController, UINavigationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    private let store: LogList

    // init(store:) は省略。この画面を UINavigationController の一番下に置き、その delegate を self にする。

    override func updateProperties() {
        super.updateProperties()
        updatePath()
        updateFilterSheet()
    }

    // 積んだ画面:状態の path と、表示中の画面の並びを比べ、違えば合わせる。
    private func updatePath() {
        guard let navigationController else { return }
        let shown = navigationController.viewControllers.dropFirst().compactMap { $0 as? LogDetailViewController }
        let details = store.state.path.map { destination in
            switch destination {
            case let .detail(detail): detail
            }
        }
        guard shown.map(\.store) != details else { return }
        // 表示中の画面は作り直さずに使う。
        let viewControllers = details.map { detail in
            shown.first { $0.store === detail } ?? LogDetailViewController(store: detail)
        }
        navigationController.setViewControllers([self] + viewControllers, animated: true)
    }

    // 戻るボタンや端からのスワイプで戻ったときも、状態を直接短くせず、残った画面の数を Action で送る。
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        let count = navigationController.viewControllers.count - 1
        guard count < store.state.path.count else { return }
        Task { await store.send(.pathPopped(count: count)) }
    }

    // 子のストアがあればシートを出し、無ければ閉じる。
    private func updateFilterSheet() {
        switch (store.state.filter, presentedViewController) {
        case let (filter?, nil):
            let sheet = UINavigationController(rootViewController: LogFilterViewController(store: filter))
            sheet.presentationController?.delegate = self
            present(sheet, animated: true)
        case (nil, .some):
            dismiss(animated: true)
        default:
            break
        }
    }

    // 下へのスワイプで閉じたときも、状態を直接 nil にせず Action を送る。
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        Task { await store.send(.filterDismissed) }
    }
}
```

## 気をつけること

- **状態から画面を出し入れする所は、自分で差分を見る。** SwiftUI は `state.filter` や `state.path` を渡せば出し入れまでしてくれるが、
  UIKit では「今の状態」と「今出ている画面」を比べて `present` / `dismiss` / `push` / `pop` を呼ぶ必要がある。UIKit で一番手間がかかる所。
- **iOS 26 より前で使うとき。** iOS 18 では Info.plist に `UIObservationTrackingEnabled` を `YES` で足すと、
  `viewWillLayoutSubviews()` などで読んだ値が追われる(`updateProperties()` は iOS 26 から)。
  iOS 17 では `withObservationTracking` で自分で購読し直す必要がある。
- **`presentation`、`navigationPath`、`binding`、`onDeepLink` は SwiftUI 専用。** UIKit だけのアプリで使うなら、これらを `Rill` から
  別のターゲット(例:`RillSwiftUI`)へ分けると、`Rill` が SwiftUI に依存しなくなる。
- **テストは変わらない。** ストアのテストは View を立ち上げないので、UIKit でも SwiftUI でも同じものが使える。
  SwiftUI と UIKit の画面を混ぜても、同じストアを渡せばよい。

## 参考

- [Updating views automatically with observation tracking in UIKit(Apple)](https://developer.apple.com/documentation/uikit/updating-views-automatically-with-observation-tracking-in-uikit)
