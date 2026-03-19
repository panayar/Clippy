import ApplicationServices
import Foundation

/// Simulates a Cmd+V keystroke using CGEvent to auto-paste clipboard content.
enum AutoPaster {
    /// Paste after a delay so the target app regains focus first.
    /// Runs entirely on a background thread — main thread is never touched.
    static func pasteAfterDelay(milliseconds: Int = 200) {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
            guard Permissions.isAccessibilityEnabled() else { return }

            // Use .privateState so our simulated keys don't interfere with
            // the user's real keyboard state or with web apps (WhatsApp Web,
            // Slack, etc.) that have their own keyboard event handlers.
            let source = CGEventSource(stateID: .privateState)
            let vKeyCode: CGKeyCode = 0x09

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }

            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand

            // Post at session level — less intrusive than HID level,
            // works better with browser-based apps.
            keyDown.post(tap: .cgSessionEventTap)
            usleep(12000) // 12ms gap
            keyUp.post(tap: .cgSessionEventTap)
        }
    }
}
