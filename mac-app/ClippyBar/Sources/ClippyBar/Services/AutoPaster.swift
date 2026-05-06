import AppKit
import Carbon

/// Synthesizes a ⌘V keystroke so the picked clipboard item is pasted into
/// whatever app was frontmost before the picker opened. Requires the user
/// to have granted Accessibility permission; without it the system silently
/// drops the synthesized event and the user just sees the value land on the
/// clipboard with no paste.
enum AutoPaster {
    /// Posts a ⌘V key-down/up pair after `milliseconds`. The delay gives the
    /// previous app's window time to come back into focus before we type.
    static func pasteAfterDelay(milliseconds: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
            paste()
        }
    }

    static func paste() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let vCode = UInt16(kVK_ANSI_V)

        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true)
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)

        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false)
        cmdUp?.flags = .maskCommand
        cmdUp?.post(tap: .cghidEventTap)
    }
}
