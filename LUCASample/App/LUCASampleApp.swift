import SwiftUI

@main
struct LUCASampleApp: App {

    // MARK: SwiftUI Properties

    @State private var store = AppRoot(.live)

    // MARK: Content Properties

    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
        }
    }
}
