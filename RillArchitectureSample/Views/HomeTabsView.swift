import Rill
import SwiftUI

/// タブの画面
struct HomeTabsView: View {

    // MARK: Properties

    let store: HomeTabs

    // MARK: Content Properties

    var body: some View {
        // 選んでいるタブも状態。タブを押したときも Action を通す。
        TabView(selection: store.binding(\.state.selectedTab, send: { .tabSelected($0) })) {
            Tab("記録する", systemImage: "square.and.pencil", value: .newLog) {
                NavigationStack {
                    NewLogView(store: store.state.newLog)
                        .toolbar { signOutButton }
                }
            }
            Tab("一覧", systemImage: "books.vertical", value: .logList) {
                // 積んだ画面は LogList の状態(path)。戻ったときも Action を通す。
                let logList = store.state.logList
                NavigationStack(path: logList.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })) {
                    LogListView(store: logList)
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
