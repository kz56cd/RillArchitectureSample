import SwiftUI

extension Composable {
    /// 子のストアを出す画面(シートなど)に渡す Binding
    ///
    /// ストアの状態は `private(set)` なので、`$store.detail` のようには束縛できない。
    /// SwiftUI が画面を閉じたとき(下へのスワイプなど)も、状態を直接 `nil` にせず、
    /// `dismissAction` を送って `reduce(_:)` に閉じさせる。
    func presentation<Child>(_ keyPath: KeyPath<Self, Child?>, dismiss dismissAction: Action) -> Binding<Child?> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { newValue in
                guard case .none = newValue else { return }
                Task { await self.send(dismissAction) }
            }
        )
    }
}
