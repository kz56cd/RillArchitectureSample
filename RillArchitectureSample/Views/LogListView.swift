import Rill
import SwiftUI

/// 記録の一覧の画面
///
/// `NavigationStack` は親(HomeTabsView)が `store.navigationPath(...)` で作り、ここでは積む画面を決める。
struct LogListView: View {

    // MARK: Properties

    let store: LogList

    // MARK: Content Properties

    var body: some View {
        List {
            if store.state.loadFailed {
                Text("読み込めませんでした。")
                    .foregroundStyle(.red)
            }
            ForEach(store.state.visibleLogs) { log in
                // 積むのも Action で行う。NavigationLink(value:) は使わない。
                Button {
                    Task { await store.send(.logTapped(log)) }
                } label: {
                    ReadingLogRow(log: log)
                }
                .tint(.primary)
            }
        }
        .overlay {
            if store.state.logs.isEmpty, !store.state.loadFailed {
                ContentUnavailableView("記録はまだありません", systemImage: "books.vertical")
            } else if store.state.visibleLogs.isEmpty {
                ContentUnavailableView("当てはまる記録はありません", systemImage: "line.3.horizontal.decrease")
            }
        }
        .navigationTitle("一覧")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("絞り込む", systemImage: "line.3.horizontal.decrease") {
                    Task { await store.send(.filterButtonTapped) }
                }
            }
        }
        .task { await store.send(.task) }
        .navigationDestination(for: LogList.Destination.self) { destination in
            switch destination {
            case let .detail(detail):
                LogDetailView(store: detail)
            }
        }
        // 子のストアがあればシートを出す。スワイプで閉じたときも Action を通す。
        .sheet(item: store.presentation(\.state.filter, dismiss: .filterDismissed)) { filter in
            LogFilterView(store: filter)
        }
    }
}

/// 1 件の記録の詳しい画面
struct LogDetailView: View {

    // MARK: Properties

    let store: LogDetail

    // MARK: Content Properties

    var body: some View {
        List {
            ReadingLogRow(log: store.state.log)
            Section {
                Button("削除する", role: .destructive) {
                    Task { await store.send(.deleteButtonTapped) }
                }
                .disabled(store.state.isDeleting)
            } footer: {
                if store.state.deleteFailed {
                    Text("削除できませんでした。")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("記録")
    }
}

/// 一覧を評価で絞り込む画面
struct LogFilterView: View {

    // MARK: Properties

    let store: LogFilter

    // MARK: Content Properties

    var body: some View {
        NavigationStack {
            List {
                option("すべて", rating: nil)
                ForEach(1 ... 5, id: \.self) { rating in
                    option("評価 \(rating) 以上", rating: rating)
                }
            }
            .navigationTitle("絞り込む")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        Task { await store.send(.cancelButtonTapped) }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func option(_ title: String, rating: Int?) -> some View {
        Button {
            Task { await store.send(.ratingSelected(rating)) }
        } label: {
            LabeledContent(title) {
                if store.state.minimumRating == rating {
                    Image(systemName: "checkmark")
                }
            }
        }
        .tint(.primary)
    }
}

#Preview {
    let store = LogList(.testDependencies())
    NavigationStack(path: store.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })) {
        LogListView(store: store)
    }
}
