import AppKit
import SwiftUI

extension Notification.Name {
    static let clipBarMoveUp = Notification.Name("clipBarMoveUp")
    static let clipBarMoveDown = Notification.Name("clipBarMoveDown")
    static let clipBarSelect = Notification.Name("clipBarSelect")
    static let clipBarPickerShown = Notification.Name("clipBarPickerShown")
    static let clipBarDelete = Notification.Name("clipBarDelete")
    static let clipBarTogglePin = Notification.Name("clipBarTogglePin")
    static let clipBarEditItem = Notification.Name("clipBarEditItem")
    static let clipBarSaveEdit = Notification.Name("clipBarSaveEdit")
    static let clipBarCancelEdit = Notification.Name("clipBarCancelEdit")
}

/// Custom panel that accepts first-mouse clicks so SwiftUI tap gestures
/// work even when the panel hasn't stolen focus from the previous app.
final class ClickThroughPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Visual effect view that accepts first-mouse so clicks register immediately.
final class FirstMouseVisualEffectView: NSVisualEffectView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

/// Manages a floating NSPanel that hosts the clipboard picker UI.
@MainActor
final class PickerWindowController: NSObject, NSWindowDelegate {
    static let shared = PickerWindowController()

    /// Set by PickerView when the edit overlay is open so the key
    /// monitor can route Return → save and Escape → cancel.
    var isEditing = false

    private var panel: NSPanel?
    private var store: ClipboardStore?
    private var monitor: ClipboardMonitor?
    private var keyMonitor: Any?

    /// The app that was active before we showed the picker.
    /// We return focus here after the user picks an item.
    var previousApp: NSRunningApplication?

    private override init() {}

    func configure(store: ClipboardStore, monitor: ClipboardMonitor) {
        self.store = store
        self.monitor = monitor
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication

        if panel == nil {
            createPanel()
        }
        guard let panel = panel else { return }
        positionPanelAtCursor(panel)
        panel.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        installKeyMonitor()

        // Tell PickerView to reset selection to the most-recent item (index 0).
        NotificationCenter.default.post(name: .clipBarPickerShown, object: nil)
    }

    func hide() {
        removeKeyMonitor()
        panel?.orderOut(nil)
    }

    /// Hide the picker and return focus to the previous app.
    func hideAndRestoreFocus() {
        hide()
        // Re-activate the app that was in front before the picker opened
        if let prev = previousApp {
            if #available(macOS 14.0, *) {
                prev.activate()
            } else {
                prev.activate(options: .activateIgnoringOtherApps)
            }
        }
    }

    func toggle() {
        if let panel = panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide()
        return false
    }

    func windowDidResignKey(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: "dismissOnClickOutside") else { return }
        hide()
    }

    // MARK: - Panel Creation

    private func createPanel() {
        let panel = ClickThroughPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 420),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isFloatingPanel = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.delegate = self
        panel.minSize = NSSize(width: 320, height: 260)
        panel.maxSize = NSSize(width: 600, height: 700)

        // The root visual effect view provides the native macOS frosted glass
        let visualEffect = FirstMouseVisualEffectView()
        visualEffect.material = .sidebar
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active

        guard let store = store, let monitor = monitor else {
            print("[ClippyBar] PickerWindowController not configured — call configure() first")
            return
        }

        let pickerView = PickerView()
            .environmentObject(store)
            .environmentObject(monitor)

        let hostingView = NSHostingView(rootView: pickerView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Stack: visual effect behind, hosting view on top
        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        panel.contentView = visualEffect
        positionPanelAtCursor(panel)
        self.panel = panel
    }

    /// Position the panel near the mouse cursor, clamped to screen edges.
    private func positionPanelAtCursor(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let panelSize = panel.frame.size

        // Find the screen containing the cursor
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        guard let screen = screen else { return }
        let visible = screen.visibleFrame

        // Place the panel centered horizontally on the cursor, top-aligned to cursor
        var x = mouse.x - panelSize.width / 2
        var y = mouse.y - panelSize.height - 8 // 8pt below cursor

        // If not enough room below, place above cursor
        if y < visible.minY {
            y = mouse.y + 24
        }

        // Clamp to screen bounds
        x = max(visible.minX + 4, min(x, visible.maxX - panelSize.width - 4))
        y = max(visible.minY + 4, min(y, visible.maxY - panelSize.height - 4))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Key Monitor (tied to panel visibility, not SwiftUI lifecycle)

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return event }
            // When the edit overlay is open, Return saves and Escape cancels
            if self.isEditing {
                switch event.keyCode {
                case 36: // Return — save edit
                    NotificationCenter.default.post(name: .clipBarSaveEdit, object: nil)
                    return nil
                case 53: // Escape — cancel edit
                    NotificationCenter.default.post(name: .clipBarCancelEdit, object: nil)
                    return nil
                default:
                    return event
                }
            }

            switch event.keyCode {
            case 53: // Escape
                self.hide()
                return nil
            case 126: // Up arrow
                NotificationCenter.default.post(name: .clipBarMoveUp, object: nil)
                return nil
            case 125: // Down arrow
                NotificationCenter.default.post(name: .clipBarMoveDown, object: nil)
                return nil
            case 36: // Return/Enter
                NotificationCenter.default.post(name: .clipBarSelect, object: nil)
                return nil
            case 51: // Delete/Backspace
                // Cmd+Delete deletes the selected clipboard item
                if event.modifierFlags.contains(.command) {
                    NotificationCenter.default.post(name: .clipBarDelete, object: nil)
                    return nil
                }
                // Plain backspace goes to the search field
                return event
            default:
                // Cmd+P to toggle pin
                if event.modifierFlags.contains(.command) && event.keyCode == 35 {
                    NotificationCenter.default.post(name: .clipBarTogglePin, object: nil)
                    return nil
                }
                // Cmd+E to edit selected item
                if event.modifierFlags.contains(.command) && event.keyCode == 14 {
                    NotificationCenter.default.post(name: .clipBarEditItem, object: nil)
                    return nil
                }
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor {
            NSEvent.removeMonitor(m)
            keyMonitor = nil
        }
    }
}
