import Foundation
import UIKit

/// ストアが受ける通知の名前
///
/// ストアが UIKit に依存しないよう、名前はここで言い換える。
nonisolated extension Notification.Name {
    /// アプリが前面に来た
    static let appBecameActive = UIApplication.didBecomeActiveNotification
}
