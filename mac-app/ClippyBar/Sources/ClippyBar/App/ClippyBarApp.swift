import SwiftUI

@main
struct ClippyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The menu bar icon is managed by MenuBarController (NSStatusItem)
        // via AppDelegate, not by a SwiftUI MenuBarExtra — MenuBarExtra has
        // a history of silently failing to render its icon.
        Settings { EmptyView() }
    }
}
