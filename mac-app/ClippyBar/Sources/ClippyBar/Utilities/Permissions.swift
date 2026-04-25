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
    /// System Settings with a toggle — without showing Apple's native
    /// "would like to control this computer" dialog (our custom
    /// onboarding already opens Settings, so the system dialog is
    /// redundant and confusing).
    ///
    /// There's no single Apple-documented silent API that reliably
    /// registers on every macOS version, so we fire three different
    /// triggers. Whichever succeeds, succeeds: the call itself fails
    /// without permission, but TCC still lists the process afterwards.
    @discardableResult
    static func registerInAccessibilityList() -> Bool {
        // 1. Documented check with prompt explicitly disabled.
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: false] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // 2. Probe a real AX API on the system-wide element.
        let systemWide = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &value
        )

        // 3. Attempt to install a global event tap — also requires AX
        //    and registers the process in TCC when it fails.
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) {
            CFMachPortInvalidate(tap)
        }

        return AXIsProcessTrusted()
    }

    /// Opens System Settings → Privacy & Security → Accessibility.
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
