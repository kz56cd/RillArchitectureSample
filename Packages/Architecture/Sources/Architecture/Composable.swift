/// ストアの決まり
///
/// LUCA の `Composable`(https://github.com/Kyome22/Telescopure の `Composable.swift`)をもとにしたもの。
///
/// LUCA との違いは、状態を 1 つの `State` にまとめて持つこと。
///
/// - 状態は `State` の構造体にまとめ、`private(set) var state` で持つ。
/// - 状態を変える入口は `send(_:)` の 1 つだけ。
/// - `reduce(_:)` で自分の状態を変えてから、`action` で親へ伝える。
/// - 親は子を作るときに `action` を渡し、子の Action を自分の Action に包んで受け取る。
///
/// モジュールの既定の隔離を MainActor にしているので、`@MainActor` は書かない。
public protocol Composable: AnyObject {
    associatedtype State
    associatedtype Action: Sendable

    /// 画面の状態。書き換えてよいのは `reduce(_:)` だけなので、`private(set)` で持つ
    var state: State { get }

    /// 親への通知
    var action: (Action) async -> Void { get }

    /// 自分の状態の更新。状態を書き換えてよいのはここだけ
    func reduce(_ action: Action) async
}

public extension Composable {
    func reduce(_ action: Action) async {}

    /// Action を送る。
    ///
    /// 自分の状態を確定してから親へ伝える。`reduce(_:)` の終わりまで待つので、
    /// テストでは `await send(...)` のあとに状態を確かめればよい。
    func send(_ action: Action) async {
        await reduce(action)
        await self.action(action)
    }

    /// 状態を字下げした文字列。子のストアの状態も入れ子で並べる
    ///
    /// LLDB では `po store.prettyState` で見られる。
    var prettyState: String {
        PrettyPrinter.format(state)
    }

    /// 状態を字下げしてコンソールに出す。
    func printState() {
        print(prettyState)
    }
}
