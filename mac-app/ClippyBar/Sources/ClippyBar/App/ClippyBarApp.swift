import SwiftUI

@main
struct ClippyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("ClippyBar", systemImage: "clipboard") {
            MenuBarView()
                .environmentObject(AppState.shared.store)
                .environmentObject(AppState.shared.monitor)
        }
    }
}
