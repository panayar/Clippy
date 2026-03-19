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

    private var accessibilityTimer: Timer?
    private static let onboardingKey = "completedOnboardingV4"

    private var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: Self.onboardingKey)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            let state = AppState.shared

            // Always start these — they don't need accessibility
            state.monitor.start(store: state.store)
            PickerWindowController.shared.configure(store: state.store, monitor: state.monitor)
            registerHotkey()

            if isFirstLaunch {
                // Flow 1: New user — full onboarding
                OnboardingWindowController.shared.showFullOnboarding {
                    UserDefaults.standard.set(true, forKey: Self.onboardingKey)
                    self.registerHotkey()
                    self.startAccessibilityMonitor()
                }
            } else if Permissions.isAccessibilityEnabled() {
                // Returning user with access — fully functional
                startAccessibilityMonitor()
            } else {
                // Flow 2: Returning user without access — show access-only prompt
                OnboardingWindowController.shared.showAccessibilityPrompt()
                waitForAccessibilityRestore()
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

    /// Poll until accessibility is restored (returning user flow)
    @MainActor
    private func waitForAccessibilityRestore() {
        accessibilityTimer?.invalidate()
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if Permissions.isAccessibilityEnabled() {
                    self.accessibilityTimer?.invalidate()
                    self.accessibilityTimer = nil
                    OnboardingWindowController.shared.dismissIfShowing()
                    self.registerHotkey()
                    // Show celebration screen
                    OnboardingWindowController.shared.showCelebration {
                        self.startAccessibilityMonitor()
                    }
                }
            }
        }
    }

    /// Monitor for accessibility being revoked while running
    @MainActor
    private func startAccessibilityMonitor() {
        accessibilityTimer?.invalidate()
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if !Permissions.isAccessibilityEnabled() {
                    self.accessibilityTimer?.invalidate()
                    OnboardingWindowController.shared.showAccessibilityPrompt()
                    self.waitForAccessibilityRestore()
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        accessibilityTimer?.invalidate()
        HotkeyManager.shared.unregister()
    }
}
