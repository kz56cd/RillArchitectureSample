import SwiftUI

public extension View {
    /// URL で開かれたとき、行き先をストアへ Action として送る。
    ///
    /// カスタム URL スキーム(`onOpenURL`)とユニバーサルリンク(`onContinueUserActivity`)の両方を受ける。
    /// アプリの一番上の View に付け、一番上のストアを渡す。
    ///
    /// ```swift
    /// AppRootView(store: store)
    ///     .onDeepLink(AppLink.self, to: store) { .deepLinkOpened($0) }
    /// ```
    func onDeepLink<Store: Composable, Link: DeepLink>(
        _ type: Link.Type,
        to store: Store,
        action: @escaping (Link) -> Store.Action
    ) -> some View {
        onOpenURL { url in
            Task { await store.open(url, as: type, action: action) }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            Task { await store.open(url, as: type, action: action) }
        }
    }
}
