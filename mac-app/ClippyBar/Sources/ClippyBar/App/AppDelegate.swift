import AppKit
import SwiftUI

/// Shared app state accessible across the app.
@MainActor
final class AppState {
    static let shared = AppState()
    let store = ClipboardStore()
    let monitor = ClipboardMonitor()
    private init() {}
}

/// Application delegate handling launch-time setup.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private static let onboardingKey = "completedOnboardingV5"

    private var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: Self.onboardingKey)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            let state = AppState.shared

            state.monitor.start(store: state.store)
            PickerWindowController.shared.configure(store: state.store, monitor: state.monitor)
            MenuBarController.shared.setup(store: state.store, monitor: state.monitor)
            registerHotkey()

            if isFirstLaunch {
                OnboardingWindowController.shared.showFullOnboarding {
                    UserDefaults.standard.set(true, forKey: Self.onboardingKey)
                }
            }
        }
    }

    @MainActor
    private func registerHotkey() {
        let hotkeyManager = HotkeyManager.shared
        hotkeyManager.onHotkey = {
            Task { @MainActor in
                PickerWindowController.shared.toggle()
            }
        }
        hotkeyManager.register()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }
}
