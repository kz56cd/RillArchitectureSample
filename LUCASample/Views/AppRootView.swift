import SwiftUI

/// ログインの画面とタブの画面の出し分け。見た目は持たない
struct AppRootView: View {

    // MARK: Properties

    let store: AppRoot

    // MARK: Content Properties

    var body: some View {
        switch store.screen {
        case let .login(login):
            LoginView(store: login)
        case let .main(homeTabs):
            HomeTabsView(store: homeTabs)
        }
    }
}

#Preview {
    AppRootView(store: AppRoot(.testDependencies()))
}
