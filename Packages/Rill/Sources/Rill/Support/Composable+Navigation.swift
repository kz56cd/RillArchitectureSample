import SwiftUI

public extension Composable {
    /// 子のストアを積む画面(`NavigationStack`)に渡す Binding
    ///
    /// ストアの状態は `private(set)` なので、`$store.state.path` のようには束縛できない。
    /// SwiftUI が画面を戻したとき(戻るボタン、端からのスワイプ)も、状態を直接短くせず、
    /// `popAction` に残った数を渡して作った Action を送り、`reduce(_:)` に戻させる。
    ///
    /// 積むのは `reduce(_:)` の中だけで行う。SwiftUI が要素を足そうとしても(`NavigationLink(value:)` など)無視する。
    ///
    /// ```swift
    /// NavigationStack(path: store.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })) { ... }
    /// ```
    func navigationPath<Element>(_ keyPath: KeyPath<Self, [Element]>, pop popAction: @escaping (Int) -> Action) -> Binding<[Element]> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { newValue in
                guard newValue.count < self[keyPath: keyPath].count else { return }
                Task { await self.send(popAction(newValue.count)) }
            }
        )
    }
}

/// 同じストアかどうか(`===`)で比べ、ハッシュ値を作る。
///
/// `NavigationStack` の path の要素や `navigationDestination(item:)` の値は `Hashable` でなければならない。
/// ストアは状態が変わっても同じ画面なので、中身ではなく同じものかどうかで比べる。
///
/// ```swift
/// final class LogDetail: Composable, IdentityHashable { ... }
///
/// enum Destination: Hashable {
///     case detail(LogDetail)
/// }
/// ```
public protocol IdentityHashable: AnyObject, Hashable {}

public extension IdentityHashable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
