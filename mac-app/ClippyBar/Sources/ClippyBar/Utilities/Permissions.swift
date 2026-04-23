import AppKit
import ApplicationServices
import Foundation

/// Helpers for checking and requesting macOS accessibility permissions.
enum Permissions {
    /// Returns true if the app has been granted accessibility access.
    static func isAccessibilityEnabled() -> Bool {
        AXIsProcessTrusted()
    }

    /// Register the app in TCC's Accessibility list so it appears in
    /// System Settings with a toggle. We use Apple's documented
    /// `AXIsProcessTrustedWithOptions(prompt: true)` path because that is
    /// the only call that is *guaranteed* to add the process to the
    /// Accessibility list on every macOS version we support. Silent
    /// variants (prompt: false, or just probing an AX API) are not
    /// reliable — on a fresh install of 1.3.2 the app failed to appear
    /// in the list at all, forcing users to add it by hand.
    ///
    /// Yes, this shows Apple's own "X would like to control this
    /// computer" dialog alongside our custom onboarding screen. We
    /// accept that small duplication in exchange for the app reliably
    /// landing in the list with a toggle the user can flip.
    @discardableResult
    static func registerInAccessibilityList() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Opens System Settings → Privacy & Security → Accessibility.
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
