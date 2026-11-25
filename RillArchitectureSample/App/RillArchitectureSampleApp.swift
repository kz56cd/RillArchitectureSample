import Rill
import SwiftUI

@main
struct RillArchitectureSampleApp: App {

    // MARK: SwiftUI Properties

    @State private var store = AppRoot(.live)

    // MARK: Content Properties

    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
                // URL で開かれたら、行き先を一番上のストアへ Action として送る。
                .onDeepLink(AppLink.self, to: store) { .deepLinkOpened($0) }
        }
    }
}
