/// ストアの決まり
///
/// LUCA の `Composable` と同じもの(https://github.com/Kyome22/Telescopure の `Composable.swift`)。
///
/// - 状態を変える入口は `send(_:)` の 1 つだけ。
/// - `reduce(_:)` で自分の状態を変えてから、`action` で親へ伝える。
/// - 親は子を作るときに `action` を渡し、子の Action を自分の Action に包んで受け取る。
///
/// モジュールの既定の隔離を MainActor にしているので、`@MainActor` は書かない。
public protocol Composable: AnyObject {
    associatedtype Action: Sendable

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
}
