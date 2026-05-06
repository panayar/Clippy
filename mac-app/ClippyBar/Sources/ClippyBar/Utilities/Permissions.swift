import AppKit
import ApplicationServices

/// Accessibility permission helpers. ClippyBar needs Accessibility access so
/// it can synthesize a ⌘V keystroke after the user picks an item; without it
/// auto-paste silently fails.
enum Permissions {
    /// Returns true if our process is currently trusted for Accessibility.
    /// Uses the non-prompting API so we can poll without spamming the user.
    static func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Triggers the system prompt that registers ClippyBar in the
    /// Accessibility list under System Settings → Privacy & Security.
    /// macOS only adds an app to the list once it has *asked* for the
    /// permission, so we have to call this before opening Settings, otherwise
    /// the user sees an empty list with nothing to toggle.
    static func registerInAccessibilityList() {
        let opts: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true
        ]
        _ = AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }

    /// Opens the Accessibility pane in System Settings (macOS 13+) /
    /// System Preferences. The deep link is the same on both.
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
