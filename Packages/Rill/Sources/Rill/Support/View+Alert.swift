import SwiftUI

public extension View {
    /// ストアの状態にある `AlertState` を、アラートとして出す。
    ///
    /// 閉じると、どの閉じ方でも `dismiss` がちょうど 1 回届く。ボタンを押したときは、そのあとにボタンの Action が届く。
    /// `dismiss` を受けた `reduce` は、状態を nil にする。
    ///
    /// ```swift
    /// .alert(store: store, state: \.state.alert, dismiss: .alertDismissed)
    /// ```
    func alert<Store: Composable>(
        store: Store,
        state keyPath: KeyPath<Store, AlertState<Store.Action>?>,
        dismiss dismissAction: Store.Action
    ) -> some View {
        let alert = store[keyPath: keyPath]
        return self.alert(
            alert?.title ?? "",
            isPresented: store.isAlertPresented(keyPath, dismiss: dismissAction),
            presenting: alert
        ) { alert in
            AlertButtons(store: store, keyPath: keyPath, alert: alert, dismissAction: dismissAction)
        } message: { alert in
            if let message = alert.message {
                Text(message)
            }
        }
    }

    /// ストアの状態にある `AlertState` を、確認ダイアログとして出す。
    ///
    /// 外を押して閉じたときも、`dismiss` がちょうど 1 回届く。決まりは `alert(store:state:dismiss:)` と同じ。
    func confirmationDialog<Store: Composable>(
        store: Store,
        state keyPath: KeyPath<Store, AlertState<Store.Action>?>,
        dismiss dismissAction: Store.Action
    ) -> some View {
        let dialog = store[keyPath: keyPath]
        return confirmationDialog(
            dialog?.title ?? "",
            isPresented: store.isAlertPresented(keyPath, dismiss: dismissAction),
            titleVisibility: .visible,
            presenting: dialog
        ) { dialog in
            AlertButtons(store: store, keyPath: keyPath, alert: dialog, dismissAction: dismissAction)
        } message: { dialog in
            if let message = dialog.message {
                Text(message)
            }
        }
    }
}

extension Composable {
    /// 出ているかどうかの Binding。SwiftUI が閉じたら(false を書いたら)、閉じる Action を送る。
    func isAlertPresented<Value>(_ keyPath: KeyPath<Self, Value?>, dismiss dismissAction: Action) -> Binding<Bool> {
        Binding(
            get: { self[keyPath: keyPath] != nil },
            set: { isPresented in
                guard !isPresented else { return }
                Task { await self.dismissAlert(keyPath, dismiss: dismissAction) }
            }
        )
    }
}

/// アラートと確認ダイアログのボタンを並べる。
private struct AlertButtons<Store: Composable>: View {

    // MARK: Properties

    let store: Store
    let keyPath: KeyPath<Store, AlertState<Store.Action>?>
    let alert: AlertState<Store.Action>
    let dismissAction: Store.Action

    // MARK: Content Properties

    var body: some View {
        ForEach(alert.buttons.indices, id: \.self) { index in
            let button = alert.buttons[index]
            Button(button.title, role: button.role.map(ButtonRole.init)) {
                Task { await store.tapAlertButton(button, in: keyPath, dismiss: dismissAction) }
            }
        }
    }
}

private extension ButtonRole {
    init<Action>(_ role: AlertButton<Action>.Role) {
        switch role {
        case .cancel: self = .cancel
        case .destructive: self = .destructive
        }
    }
}
