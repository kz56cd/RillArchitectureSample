import SwiftUI

/// 記録する画面
///
/// 入力中と保存したあとを、ストアの `phase` で出し分ける。
struct NewLogView: View {

    // MARK: Properties

    let store: NewLog

    // MARK: Content Properties

    var body: some View {
        Group {
            switch store.phase {
            case let .editing(form):
                LogFormView(store: form)
            case let .saved(log):
                List {
                    Section("保存しました") {
                        ReadingLogRow(log: log)
                    }
                    Section {
                        Button("続けて記録する") {
                            Task { await store.send(.writeAnotherButtonTapped) }
                        }
                    }
                }
            }
        }
        .navigationTitle("記録する")
    }
}

/// 記録の入力欄
struct LogFormView: View {

    // MARK: Properties

    @Bindable var store: LogForm

    // MARK: Content Properties

    var body: some View {
        Form {
            Section {
                // 入力欄の値だけは、例外として直接束縛する。
                field("書名", text: $store.draft.title, field: .title)
                field("読んだページ数", text: $store.draft.pages, field: .pages)
                    .keyboardType(.numberPad)
                field("評価(1〜5・任意)", text: $store.draft.rating, field: .rating)
                    .keyboardType(.numberPad)
            } footer: {
                if !store.invalidFields.isEmpty {
                    Text("赤い欄を確かめてください。書名は 50 文字まで、ページ数は 1〜2000 です。")
                        .foregroundStyle(.red)
                } else if store.saveFailed {
                    Text("保存できませんでした。")
                        .foregroundStyle(.red)
                }
            }
            Section {
                Button("保存する") {
                    Task { await store.send(.saveButtonTapped) }
                }
                .disabled(store.isSaving)
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, field: ReadingLogField) -> some View {
        TextField(title, text: text)
            .foregroundStyle(store.invalidFields.contains(field) ? .red : .primary)
    }
}

/// 記録の 1 行
struct ReadingLogRow: View {

    // MARK: Properties

    let log: ReadingLog

    // MARK: Content Properties

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(log.title)
                .font(.headline)
            HStack {
                Text("\(log.pages) ページ")
                if let rating = log.rating {
                    Text(String(repeating: "★", count: rating))
                }
                Text(log.loggedAt, format: .dateTime.month().day().hour().minute())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        NewLogView(store: NewLog(.testDependencies()))
    }
}
