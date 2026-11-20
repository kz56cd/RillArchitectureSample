import SwiftUI

@main
struct RillArchitectureSampleApp: App {

    // MARK: SwiftUI Properties

    @State private var store = AppRoot(.live)

    // MARK: Content Properties

    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
        }
    }
}
