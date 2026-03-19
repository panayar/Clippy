import Carbon
import Cocoa
import Foundation

/// Manages a global keyboard shortcut using the Carbon Events API.
/// Default hotkey: Option + V.
final class HotkeyManager {
    static let shared = HotkeyManager()

    /// Called when the hotkey is pressed.
    var onHotkey: (() -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    /// Current key code (Carbon virtual key code).
    var keyCode: UInt32 {
        get { UInt32(UserDefaults.standard.integer(forKey: "hotkeyKeyCode").nonZero ?? Int(kVK_ANSI_V)) }
        set { UserDefaults.standard.set(Int(newValue), forKey: "hotkeyKeyCode") }
    }

    /// Current modifier flags (Carbon modifier mask).
    var modifiers: UInt32 {
        get { UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers").nonZero ?? Int(optionKey)) }
        set { UserDefaults.standard.set(Int(newValue), forKey: "hotkeyModifiers") }
    }

    private init() {}

    /// Register the global hotkey with the system.
    func register() {
        unregister()

        // Install a Carbon event handler for hotkey events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onHotkey?()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        // Register the actual hotkey combination
        let hotkeyID = EventHotKeyID(signature: OSType(0x434C4950), id: 1) // "CLIP"
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status != noErr {
            print("[ClippyBar] Failed to register hotkey, status: \(status)")
        }
    }

    /// Remove the currently registered hotkey.
    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    /// Change the hotkey to a new key code and modifier combination, then re-register.
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        register()
    }

    // MARK: - Modifier / Key Display Helpers

    /// Convert Carbon modifier mask to a human-readable string like "⌥V".
    static func displayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }

        let keyName = Self.keyName(for: keyCode)
        parts.append(keyName)
        return parts.joined()
    }

    /// Map a Carbon virtual key code to a readable key name.
    private static let keyMapping: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x25: "L", 0x26: "J", 0x28: "K", 0x2C: "/", 0x2D: "N",
            0x2E: "M", 0x31: " Space", 0x24: "↩", 0x30: "⇥",
            0x33: "⌫", 0x35: "⎋", 0x7A: "F1", 0x78: "F2",
            0x63: "F3", 0x76: "F4", 0x60: "F5", 0x61: "F6",
            0x62: "F7", 0x64: "F8", 0x65: "F9", 0x6D: "F10",
            0x67: "F11", 0x6F: "F12",
            0x7E: "↑", 0x7D: "↓", 0x7B: "←", 0x7C: "→",
    ]

    static func keyName(for keyCode: UInt32) -> String {
        keyMapping[keyCode] ?? "Key(\(keyCode))"
    }

    /// Convert NSEvent modifier flags to Carbon modifier mask.
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }
}

// Small helper to avoid 0 being treated as a valid stored default.
private extension Int {
    var nonZero: Int? {
        self == 0 ? nil : self
    }
}
