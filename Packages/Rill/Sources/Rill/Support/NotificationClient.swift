import Foundation

/// NotificationCenter の通知を、Swift Concurrency の流れ(`AsyncStream`)として受け取る依存
///
/// 通知は、画面の木のつながりと関係なく届く。アプリの外から来る出来事
/// (アプリが前面に来た、時刻やタイムゾーンが変わった、ほかのライブラリが知らせた)を、
/// ストアの Action として受けるために使う。
///
/// 画面どうしの連携には使わない。画面どうしは、共通の親が中継するか、共有のストアを依存として渡す。
///
/// ```swift
/// // View の `.task` から送る Action の中で、画面が消えるまで受け続ける。
/// case .observeNotifications:
///     for await _ in notificationClient.notifications(named: UIApplication.didBecomeActiveNotification) {
///         await send(.appBecameActive)
///     }
/// ```
nonisolated public struct NotificationClient: DependencyClient {

    // MARK: Static Properties

    public static let liveValue = NotificationClient.center(.default)

    /// 何も届かない。通知を確かめるテストでは `center(NotificationCenter())` に差し替え、そこへ post する。
    public static let testValue = NotificationClient(observe: { _, _ in {} })

    // MARK: Properties

    /// 通知を受け取り始め、止める処理を返す。`handler` は通知を送ったスレッドで、送った順に呼ばれる。
    public var observe: @Sendable (_ name: Notification.Name, _ handler: @escaping @Sendable (Notification) -> Void) -> @Sendable () -> Void

    // MARK: Initializers

    public init(observe: @escaping @Sendable (_ name: Notification.Name, _ handler: @escaping @Sendable (Notification) -> Void) -> @Sendable () -> Void) {
        self.observe = observe
    }

    // MARK: Static Functions

    /// 指定した NotificationCenter の通知を受け取る。
    public static func center(_ center: NotificationCenter) -> NotificationClient {
        NotificationClient(observe: { name, handler in
            let token = ObserverToken(center.addObserver(forName: name, object: nil, queue: nil) { notification in
                handler(notification)
            })
            return { center.removeObserver(token.value) }
        })
    }

    // MARK: Functions

    /// 通知が届くたびに、`transform` で値にして流す。
    ///
    /// `Notification` は `Sendable` ではないので、そのまま流さず、届いたスレッドで必要な値だけを取り出す。
    /// nil を返した通知は流さない。流れを受けているタスクが取り消されると、受け取りを止める。
    public func notifications<Value: Sendable>(
        named name: Notification.Name,
        transform: @escaping @Sendable (Notification) -> Value?
    ) -> AsyncStream<Value> {
        AsyncStream { continuation in
            let cancel = observe(name) { notification in
                guard let value = transform(notification) else { return }
                continuation.yield(value)
            }
            continuation.onTermination = { _ in cancel() }
        }
    }

    /// 通知が届いたことだけを流す。
    public func notifications(named name: Notification.Name) -> AsyncStream<Void> {
        notifications(named: name) { _ in () }
    }
}

/// `addObserver` が返す値を、止める処理へ渡すための入れ物。
/// 値は `removeObserver` に渡すだけで、中身には触らない。
nonisolated private final class ObserverToken: @unchecked Sendable {
    let value: any NSObjectProtocol

    init(_ value: any NSObjectProtocol) {
        self.value = value
    }
}
