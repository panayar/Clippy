import AppKit
import SwiftUI

/// Owns the menu bar NSStatusItem for ClippyBar. We use a native
/// NSStatusItem here instead of SwiftUI's MenuBarExtra because the
/// SwiftUI variant has had intermittent bugs where the icon silently
/// fails to appear, leaving users with no way to reach the app.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private weak var store: ClipboardStore?
    private weak var monitor: ClipboardMonitor?

    private override init() { super.init() }

    func setup(store: ClipboardStore, monitor: ClipboardMonitor) {
        self.store = store
        self.monitor = monitor

        // Guard against double-setup (which would create a second icon).
        if statusItem != nil { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        // autosaveName persists the user's preferred position/visibility
        // between launches, and lets macOS remember it if they ⌘-drag it.
        item.autosaveName = "ClippyBarMenuBarItem"
        item.isVisible = true
        item.behavior = [.removalAllowed]

        if let button = item.button {
            let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClippyBar")
                ?? NSImage(systemSymbolName: "list.clipboard", accessibilityDescription: "ClippyBar")
            image?.isTemplate = true
            if let image = image {
                button.image = image
            } else {
                // Last-resort fallback so the item is always visible even if
                // the SF Symbol fails to load.
                button.title = "CB"
            }
            button.toolTip = "ClippyBar"
        } else {
            NSLog("[ClippyBar] Failed to acquire NSStatusItem button")
        }

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    // MARK: - NSMenuDelegate

    /// Rebuild the menu each time it's about to open so recent items
    /// and pause state reflect the current store.
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let itemCount = store?.items.count ?? 0
        let header = NSMenuItem(title: "ClippyBar — \(itemCount) item\(itemCount == 1 ? "" : "s")", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        menu.addItem(.separator())

        if let items = store?.items, !items.isEmpty {
            for item in items.prefix(5) {
                let menuItem = NSMenuItem(
                    title: item.preview(maxLength: 40),
                    action: #selector(copyRecentItem(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.representedObject = item.id
                if item.isPinned {
                    menuItem.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
                }
                menu.addItem(menuItem)
            }
        } else {
            let empty = NSMenuItem(title: "No clipboard history yet", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }

        menu.addItem(.separator())

        let showPicker = NSMenuItem(title: "Show Clipboard History", action: #selector(openPicker), keyEquivalent: "")
        showPicker.target = self
        menu.addItem(showPicker)

        let isPaused = monitor?.isPaused == true
        let pauseItem = NSMenuItem(
            title: isPaused ? "Resume History" : "Pause History",
            action: #selector(togglePause),
            keyEquivalent: ""
        )
        pauseItem.target = self
        menu.addItem(pauseItem)

        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings\u{2026}", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit ClippyBar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func copyRecentItem(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let item = store?.items.first(where: { $0.id == id }) else { return }
        monitor?.skipNextChange = true
        let pb = NSPasteboard.general
        pb.clearContents()
        if item.contentType == .image, let img = item.loadImage(),
           let tiffData = img.tiffRepresentation {
            pb.setData(tiffData, forType: .tiff)
        } else {
            pb.setString(item.content, forType: .string)
        }
    }

    @objc private func openPicker() {
        PickerWindowController.shared.show()
    }

    @objc private func togglePause() {
        monitor?.isPaused.toggle()
    }

    @objc private func clearHistory() {
        store?.clearAll()
        monitor?.resetChangeCount()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
