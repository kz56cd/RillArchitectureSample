// 単一方向を破る書き方の見本。アプリにもテストにも含めない。
//
// `make check-unidirectional` が、アプリのソースとこのファイルを一緒に型検査し、
// 行末に expected-error の印がある行が、すべてコンパイルエラーになることを確かめる。
// ストアの状態(`state`)を書き換えられるのは、そのストアの `reduce` だけ。

import SwiftUI

func violations(root: AppRoot, homeTabs: HomeTabs, newLog: NewLog, form: LogForm, logList: LogList, detail: LogDetail) {
    // View や親から、子のストアの状態を直接書き換える。
    root.state.screen = .main(HomeTabs(.live)) // expected-error
    homeTabs.state.selectedTab = .logList // expected-error
    newLog.state.phase = .saved(logList.state.logs[0]) // expected-error
    form.state.invalidFields = [] // expected-error
    form.state.isSaving = true // expected-error
    logList.state.logs = [] // expected-error
    logList.state.path = [] // expected-error
    logList.state.filter = nil // expected-error
    // ディープリンクも、行き先の画面の状態を直接作れない。一番上のストアへ `.deepLinkOpened` を送る。
    root.state.pendingLink = .logList // expected-error
    logList.state.linkedLogMissing = false // expected-error
    detail.state.isDeleting = true // expected-error
    // 入力欄の値も、state からは書き換えられない。例外の `form.draft` を通す。
    form.state.draft = ReadingLogDraft() // expected-error
}

struct ViolatingView: View {
    @Bindable var store: LogList

    var body: some View {
        // 積んだ画面を `$store.state.path` で束縛すると、戻ったときに SwiftUI が状態を直接短くしてしまう。
        // `store.navigationPath(\.state.path, pop: { .pathPopped(count: $0) })` を使う。
        NavigationStack(path: $store.state.path) { // expected-error
            // シートを `$store.state.filter` で束縛すると、SwiftUI が状態を直接 nil にしてしまう。
            // `store.presentation(\.state.filter, dismiss: .filterDismissed)` を使う。
            Text("")
                .sheet(item: $store.state.filter) { LogFilterView(store: $0) } // expected-error
        }
    }
}

struct ViolatingTabsView: View {
    @Bindable var store: HomeTabs

    var body: some View {
        // 選んでいるタブを `$store.state.selectedTab` で束縛すると、SwiftUI が状態を直接書き換えてしまう。
        // `store.binding(\.state.selectedTab, send: { .tabSelected($0) })` を使う。
        TabView(selection: $store.state.selectedTab) { // expected-error
            Text("")
        }
    }
}
