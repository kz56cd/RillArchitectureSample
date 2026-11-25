import SwiftUI

public extension Composable {
    /// 状態の値を読み、書き込まれたら Action を送る Binding
    ///
    /// タブの選択(`TabView(selection:)`)、`Picker`、`Toggle` など、選ぶ操作に使う。
    /// 状態を直接書き換えず、`action` で作った Action を送って `reduce(_:)` に変えさせる。
    ///
    /// 入力欄(`TextField`)には使わない。入力欄は同期で書き換える必要があるので、
    /// 書き込みのできる計算プロパティを例外として出す。
    ///
    /// ```swift
    /// TabView(selection: store.binding(\.state.selectedTab, send: { .tabSelected($0) })) { ... }
    /// ```
    func binding<Value>(_ keyPath: KeyPath<Self, Value>, send action: @escaping (Value) -> Action) -> Binding<Value> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { newValue in
                Task { await self.send(action(newValue)) }
            }
        )
    }
}
