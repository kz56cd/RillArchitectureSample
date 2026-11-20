// 単一方向を破る書き方の見本。アプリにもテストにも含めない。
//
// `make check-unidirectional` が、アプリのソースとこのファイルを一緒に型検査し、
// 行末に expected-error の印がある行が、すべてコンパイルエラーになることを確かめる。
// ストアの状態(`state`)を書き換えられるのは、そのストアの `reduce` だけ。

import SwiftUI

func violations(root: AppRoot, newLog: NewLog, form: LogForm, logList: LogList, detail: LogDetail) {
    // View や親から、子のストアの状態を直接書き換える。
    root.state.screen = .main(HomeTabs(.live)) // expected-error
    newLog.state.phase = .saved(logList.state.logs[0]) // expected-error
    form.state.invalidFields = [] // expected-error
    form.state.isSaving = true // expected-error
    logList.state.logs = [] // expected-error
    logList.state.detail = nil // expected-error
    detail.state.isDeleting = true // expected-error
    // 入力欄の値も、state からは書き換えられない。例外の `form.draft` を通す。
    form.state.draft = ReadingLogDraft() // expected-error
}

struct ViolatingView: View {
    @Bindable var store: LogList

    var body: some View {
        // シートを `$store.state.detail` で束縛すると、SwiftUI が状態を直接 nil にしてしまう。
        // `store.presentation(\.state.detail, dismiss: .detailDismissed)` を使う。
        Text("")
            .sheet(item: $store.state.detail) { LogDetailView(store: $0) } // expected-error
    }
}
