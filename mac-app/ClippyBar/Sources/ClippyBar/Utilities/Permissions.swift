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
    /// permission prompt dialog. We accomplish this by invoking an AX
    /// API that requires Accessibility permission: TCC registers the
    /// calling app on first use even though the call itself fails.
    @discardableResult
    static func registerInAccessibilityList() -> Bool {
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
