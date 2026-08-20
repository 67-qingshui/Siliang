import SwiftUI

@main
struct SiliangApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup("司量 · Siliang") {
            RootView()
                .environment(store)
                .frame(minWidth: 960, minHeight: 640)
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1180, height: 780)
        .windowStyle(.hiddenTitleBar)
    }
}