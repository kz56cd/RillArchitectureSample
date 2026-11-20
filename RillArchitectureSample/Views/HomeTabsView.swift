import SwiftUI

/// タブの画面
struct HomeTabsView: View {

    // MARK: Properties

    let store: HomeTabs

    // MARK: Content Properties

    var body: some View {
        TabView {
            Tab("記録する", systemImage: "square.and.pencil") {
                NavigationStack {
                    NewLogView(store: store.state.newLog)
                        .toolbar { signOutButton }
                }
            }
            Tab("一覧", systemImage: "books.vertical") {
                NavigationStack {
                    LogListView(store: store.state.logList)
                        .toolbar { signOutButton }
                }
            }
        }
    }

    private var signOutButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("ログアウト") {
                Task { await store.send(.signOutButtonTapped) }
            }
        }
    }
}

#Preview {
    HomeTabsView(store: HomeTabs(.testDependencies()))
}
