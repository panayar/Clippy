import ApplicationServices
import Foundation

/// Helpers for checking and requesting macOS accessibility permissions.
enum Permissions {
    /// Returns true if the app has been granted accessibility access.
    static func isAccessibilityEnabled() -> Bool {
        AXIsProcessTrusted()
    }

    /// Register the app in the Accessibility list without showing the
    /// system prompt dialog.  The user still needs to flip the toggle
    /// in System Settings, but the app will already appear in the list.
    static func registerInAccessibilityList() {
        guard !isAccessibilityEnabled() else { return }

        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false
        ] as CFDictionary

        AXIsProcessTrustedWithOptions(options)
    }
}
