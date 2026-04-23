import AppKit
import ApplicationServices
import Foundation

/// Helpers for checking and requesting macOS accessibility permissions.
enum Permissions {
    /// Returns true if the app has been granted accessibility access.
    static func isAccessibilityEnabled() -> Bool {
        AXIsProcessTrusted()
    }

    /// Register the app in TCC's Accessibility list so it shows up in
    /// System Settings with a toggle — without triggering Apple's own
    /// permission prompt dialog. Per Apple's documentation,
    /// `AXIsProcessTrustedWithOptions` adds the process to the
    /// Accessibility list on first call regardless of the prompt option,
    /// so we pass `prompt: false` to skip the dialog. As a belt-and-
    /// suspenders, we also make a real AX API call which triggers TCC
    /// registration on macOS versions where the check alone doesn't.
    @discardableResult
    static func registerInAccessibilityList() -> Bool {
        // Primary: the documented registration API (no prompt dialog).
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: false] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // Fallback: an actual AX call that also nudges TCC to register
        // the process on older macOS builds.
        let systemWide = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &value
        )

        return AXIsProcessTrusted()
    }

    /// Opens System Settings → Privacy & Security → Accessibility.
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
