import AppKit

/// Shared app state accessible across the app.
@MainActor
public final class AppState {
    public static let shared = AppState()
    public let store = ClipboardStore()
    public let monitor = ClipboardMonitor()
    private init() {}
}
