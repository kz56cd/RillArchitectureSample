import Foundation

/// アラートと確認ダイアログの中身
///
/// タイトル、メッセージ、ボタンを値で持ち、ストアの状態に入れる。押したボタンは Action として送る。
/// 中身が値なので、出したかどうか、何を出したかを、View を立ち上げずにテストで確かめられる。
///
/// ```swift
/// state.confirmation = AlertState(
///     title: "この記録を削除しますか?",
///     buttons: [
///         AlertButton("削除する", role: .destructive, action: .deleteConfirmed),
///         AlertButton("キャンセル", role: .cancel)
///     ]
/// )
/// ```
///
/// SwiftUI では `alert(store:state:dismiss:)`、`confirmationDialog(store:state:dismiss:)` で出す。
nonisolated public struct AlertState<Action: Sendable>: Sendable {

    // MARK: Properties

    public var title: String
    public var message: String?
    /// 空なら、閉じるだけの「OK」を出す。
    public var buttons: [AlertButton<Action>]

    // MARK: Initializers

    public init(title: String, message: String? = nil, buttons: [AlertButton<Action>] = []) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }
}

/// アラートと確認ダイアログのボタン
nonisolated public struct AlertButton<Action: Sendable>: Sendable {

    /// ボタンの役割。SwiftUI の `ButtonRole`、UIKit の `UIAlertAction.Style` に読み替える
    public enum Role: Sendable, Equatable {
        /// やめる
        case cancel
        /// 消すなど、元に戻せないことをする
        case destructive
        /// 決める(iOS 26 から)
        case confirm
        /// 閉じる(iOS 26 から)
        case close
    }

    // MARK: Properties

    public var title: String
    public var role: Role?
    /// 押したときに送る Action。nil なら閉じるだけ
    public var action: Action?

    // MARK: Initializers

    public init(_ title: String, role: Role? = nil, action: Action? = nil) {
        self.title = title
        self.role = role
        self.action = action
    }
}

extension AlertState: Equatable where Action: Equatable {}
extension AlertButton: Equatable where Action: Equatable {}

extension Composable {
    /// アラートが出ていれば、閉じる Action を送る。
    ///
    /// SwiftUI は、ボタンを押したときに、ボタンの処理と「出ていない」への書き換えの両方を呼ぶ。
    /// どちらから呼ばれても、閉じる Action を送るのは、まだ出ているときの 1 回だけにする。
    func dismissAlert<Value>(_ keyPath: KeyPath<Self, Value?>, dismiss dismissAction: Action) async {
        guard self[keyPath: keyPath] != nil else {
            return
        }
        await send(dismissAction)
    }

    /// ボタンが押された。閉じる Action を(まだなら)送ってから、ボタンの Action を送る。
    func tapAlertButton<Value>(_ button: AlertButton<Action>, in keyPath: KeyPath<Self, Value?>, dismiss dismissAction: Action) async {
        await dismissAlert(keyPath, dismiss: dismissAction)
        if let action = button.action {
            await send(action)
        }
    }
}
