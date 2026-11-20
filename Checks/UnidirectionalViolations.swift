// 単一方向を破る書き方の見本。アプリにもテストにも含めない。
//
// `make check-unidirectional` が、アプリのソースとこのファイルを一緒に型検査し、
// 行末に expected-error の印がある行が、すべてコンパイルエラーになることを確かめる。
// ストアの状態を書き換えられるのは、そのストアの `reduce` だけ。

import SwiftUI

func violations(root: AppRoot, newLog: NewLog, form: LogForm, logList: LogList, detail: LogDetail) {
    // View や親から、子のストアの状態を直接書き換える。
    root.screen = .main(HomeTabs(.live)) // expected-error
    newLog.phase = .saved(logList.logs[0]) // expected-error
    form.invalidFields = [] // expected-error
    form.isSaving = true // expected-error
    logList.logs = [] // expected-error
    logList.detail = nil // expected-error
    detail.isDeleting = true // expected-error
}

struct ViolatingView: View {
    @Bindable var store: LogList

    var body: some View {
        // シートを `$store.detail` で束縛すると、SwiftUI が状態を直接 nil にしてしまう。
        // `store.presentation(\.detail, dismiss: .detailDismissed)` を使う。
        Text("")
            .sheet(item: $store.detail) { LogDetailView(store: $0) } // expected-error
    }
}
