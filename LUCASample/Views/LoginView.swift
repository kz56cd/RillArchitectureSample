import SwiftUI

/// ログインの画面
struct LoginView: View {

    // MARK: Properties

    @Bindable var store: Login

    // MARK: Content Properties

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 入力欄の値だけは、例外として直接束縛する。
                    TextField("ユーザー ID", text: $store.userID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    if let errorMessage = store.state.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text("\"error\" と入力すると、ログインに失敗します。")
                    }
                }
                Section {
                    Button("ログイン") {
                        Task { await store.send(.loginButtonTapped) }
                    }
                    .disabled(store.state.isSigningIn)
                }
            }
            .navigationTitle("ログイン")
        }
    }
}

#Preview {
    LoginView(store: Login(.testDependencies()))
}
