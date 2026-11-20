import SwiftUI

/// 記録の一覧の画面
struct LogListView: View {

    // MARK: Properties

    let store: LogList

    // MARK: Content Properties

    var body: some View {
        List {
            if store.loadFailed {
                Text("読み込めませんでした。")
                    .foregroundStyle(.red)
            }
            ForEach(store.logs) { log in
                Button {
                    Task { await store.send(.logTapped(log)) }
                } label: {
                    ReadingLogRow(log: log)
                }
                .tint(.primary)
            }
        }
        .overlay {
            if store.logs.isEmpty, !store.loadFailed {
                ContentUnavailableView("記録はまだありません", systemImage: "books.vertical")
            }
        }
        .navigationTitle("一覧")
        .task { await store.send(.task) }
        // 子のストアがあればシートを出す。スワイプで閉じたときも Action を通す。
        .sheet(item: store.presentation(\.detail, dismiss: .detailDismissed)) { detail in
            LogDetailView(store: detail)
        }
    }
}

/// 1 件の記録の詳しい画面
struct LogDetailView: View {

    // MARK: Properties

    let store: LogDetail

    // MARK: Content Properties

    var body: some View {
        NavigationStack {
            List {
                ReadingLogRow(log: store.log)
                Section {
                    Button("削除する", role: .destructive) {
                        Task { await store.send(.deleteButtonTapped) }
                    }
                    .disabled(store.isDeleting)
                } footer: {
                    if store.deleteFailed {
                        Text("削除できませんでした。")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("記録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        Task { await store.send(.closeButtonTapped) }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LogListView(store: LogList(.testDependencies()))
    }
}
