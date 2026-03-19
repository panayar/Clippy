import Carbon
import ServiceManagement
import SwiftUI

// MARK: - Settings Root

struct SettingsView: View {
    @State private var selectedTab: SettingsTab? = nil

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case shortcut = "Shortcut"
        case privacy = "Privacy"
        case excluded = "Excluded Apps"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gear"
            case .shortcut: return "command.square"
            case .privacy: return "lock.shield"
            case .excluded: return "xmark.app"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar - solid background, no vibrancy
            VStack(alignment: .leading, spacing: 2) {
                // Spacer for the hidden titlebar area
                Color.clear.frame(height: 22)

                ForEach(SettingsTab.allCases) { tab in
                    Button { selectedTab = tab } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13))
                                .frame(width: 18)
                            Text(tab.rawValue)
                                .font(.system(size: 13))
                            Spacer()
                        }
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.85) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 3) {
                    Text("ClippyBar v1.2.1")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)

                    HStack(spacing: 3) {
                        Text("made with")
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                        Text("\u{2764}")
                            .font(.system(size: 8))
                            .foregroundStyle(.pink)
                        Text("by")
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                        Link("Pau", destination: URL(string: "https://github.com/panayar")!)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 12)
                .padding(.bottom, 10)
            }
            .padding(.top, 8)
            .padding(.horizontal, 8)
            .frame(width: 170)
            .background(Color(nsColor: .windowBackgroundColor))

            // Detail pane
            Group {
                if let tab = selectedTab {
                    switch tab {
                    case .general: GeneralPane()
                    case .shortcut: ShortcutPane()
                    case .privacy: PrivacyPane()
                    case .excluded: ExcludedAppsPane()
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 36, weight: .thin))
                            .foregroundStyle(.quaternary)
                        Text("ClippyBar Settings")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Select a category from the sidebar")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 420)
    }
}

// MARK: - General Pane

struct GeneralPane: View {
    @AppStorage("itemLimit") private var itemLimit: Int = 50
    @AppStorage("retentionDays") private var retentionDays: Int = 7
    @AppStorage("autoPasteEnabled") private var autoPasteEnabled: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("dismissOnClickOutside") private var dismissOnClickOutside: Bool = false

    private let retentionOptions: [(label: String, days: Int)] = [
        ("1 day", 1),
        ("3 days", 3),
        ("7 days", 7),
        ("30 days", 30),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("General")
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Keep History For")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 0) {
                        ForEach(Array(retentionOptions.enumerated()), id: \.element.days) { index, option in
                            retentionButton(
                                option.label,
                                value: option.days,
                                isFirst: index == 0,
                                isLast: index == retentionOptions.count - 1
                            )
                        }
                    }
                    .frame(height: 30)

                    Text("Items older than this are automatically removed. Pinned items are kept.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Maximum Items")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 0) {
                        limitButton("50", value: 50, isFirst: true)
                        limitButton("100", value: 100)
                        limitButton("200", value: 200)
                        limitButton("500", value: 500, isLast: true)
                    }
                    .frame(height: 30)

                    Text("Safety cap — oldest non-pinned items are removed first.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    toggleRow(isOn: $autoPasteEnabled,
                              title: "Auto-paste on selection",
                              subtitle: "Paste automatically after picking an item")
                    toggleRow(isOn: $dismissOnClickOutside,
                              title: "Dismiss on click outside",
                              subtitle: "Hide the clipboard picker when you click outside of it")
                    toggleRow(isOn: $launchAtLogin,
                              title: "Launch at login",
                              subtitle: "Start ClippyBar when you log in")
                }

                Spacer()
            }
            .frame(maxWidth: 420)
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: launchAtLogin) { val in
            if #available(macOS 13.0, *) {
                try? val ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            }
        }
    }

    private func retentionButton(_ label: String, value: Int, isFirst: Bool = false, isLast: Bool = false) -> some View {
        let sel = retentionDays == value
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { retentionDays = value }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: sel ? .semibold : .regular))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(sel ? Color.accentColor.opacity(0.85) : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(sel ? .white : .primary)
        }
        .buttonStyle(.plain)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? 6 : 0,
            bottomLeadingRadius: isFirst ? 6 : 0,
            bottomTrailingRadius: isLast ? 6 : 0,
            topTrailingRadius: isLast ? 6 : 0
        ))
        .overlay(alignment: .trailing) {
            if !isLast { Rectangle().fill(Color(nsColor: .separatorColor)).frame(width: 0.5) }
        }
    }

    private func limitButton(_ label: String, value: Int, isFirst: Bool = false, isLast: Bool = false) -> some View {
        let sel = itemLimit == value
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { itemLimit = value }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: sel ? .semibold : .regular))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(sel ? Color.accentColor.opacity(0.85) : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(sel ? .white : .primary)
        }
        .buttonStyle(.plain)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? 6 : 0,
            bottomLeadingRadius: isFirst ? 6 : 0,
            bottomTrailingRadius: isLast ? 6 : 0,
            topTrailingRadius: isLast ? 6 : 0
        ))
        .overlay(alignment: .trailing) {
            if !isLast { Rectangle().fill(Color(nsColor: .separatorColor)).frame(width: 0.5) }
        }
    }

    private func toggleRow(isOn: Binding<Bool>, title: String, subtitle: String) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.tertiary)
            }
        }
        .toggleStyle(.switch)
    }
}

// MARK: - Shortcut Pane

struct ShortcutPane: View {
    @State private var currentDisplay = ""
    @State private var isRecording = false
    @State private var eventMonitor: Any?
    @State private var justSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Shortcut")
                    .font(.system(size: 20, weight: .bold))

                Text("Press this shortcut anywhere to open ClippyBar.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)

                VStack(spacing: 14) {
                    Text(currentDisplay)
                        .font(.system(size: 36, weight: .medium, design: .rounded))
                        .padding(.horizontal, 36).padding(.vertical, 18)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))

                    if justSaved {
                        Label("Updated!", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(.green)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 12) {
                    if isRecording {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Press your new shortcut\u{2026}")
                                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.orange)
                            }
                            Text("Use at least one modifier: \u{2318} \u{2325} \u{2303} \u{21E7}")
                                .font(.system(size: 11)).foregroundStyle(.tertiary)
                            Button("Cancel") { stopRecording() }.controlSize(.small)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Button { startRecording() } label: {
                                Label("Change Shortcut", systemImage: "keyboard")
                            }
                            Button { resetToDefault() } label: { Text("Reset to \u{2325}V") }
                                .controlSize(.small).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .frame(maxWidth: 420)
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .onAppear { updateDisplay() }
        .onDisappear { stopRecording() }
    }

    private func updateDisplay() {
        let m = HotkeyManager.shared
        currentDisplay = HotkeyManager.displayString(keyCode: m.keyCode, modifiers: m.modifiers)
    }

    private func startRecording() {
        isRecording = true; justSaved = false
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags.contains(.command) || flags.contains(.option)
                    || flags.contains(.control) || flags.contains(.shift) else { return event }
            HotkeyManager.shared.updateHotkey(keyCode: UInt32(event.keyCode),
                                               modifiers: HotkeyManager.carbonModifiers(from: flags))
            updateDisplay(); stopRecording()
            withAnimation { justSaved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { justSaved = false } }
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
    }

    private func resetToDefault() {
        HotkeyManager.shared.updateHotkey(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(optionKey))
        updateDisplay()
        withAnimation { justSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { justSaved = false } }
    }
}

// MARK: - Privacy Pane

struct PrivacyPane: View {
    @EnvironmentObject var store: ClipboardStore
    @EnvironmentObject var monitor: ClipboardMonitor
    @AppStorage("memoryOnlyMode") private var memoryOnlyMode: Bool = false
    @State private var showClearConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Privacy")
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $monitor.isPaused) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pause clipboard history")
                            Text("Stop recording new entries temporarily")
                                .font(.system(size: 11)).foregroundStyle(.tertiary)
                        }
                    }.toggleStyle(.switch)

                    Toggle(isOn: $memoryOnlyMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Memory-only mode")
                            Text("Nothing written to disk \u{2014} lost when app quits")
                                .font(.system(size: 11)).foregroundStyle(.tertiary)
                        }
                    }.toggleStyle(.switch)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear History").font(.system(size: 13, weight: .medium))
                        Text("\(store.items.count) items stored")
                            .font(.system(size: 11)).foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button("Clear All\u{2026}", role: .destructive) { showClearConfirm = true }
                        .alert("Clear Clipboard History?", isPresented: $showClearConfirm) {
                            Button("Cancel", role: .cancel) {}
                            Button("Clear All", role: .destructive) {
                                store.clearAll(); monitor.resetChangeCount()
                            }
                        } message: { Text("This will permanently delete all saved items.") }
                }

                Divider()

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill").foregroundStyle(.green).font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("100% Local").font(.system(size: 12, weight: .medium))
                        Text("All data stays on your Mac. Zero network connections.")
                            .font(.system(size: 11)).foregroundStyle(.tertiary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.05)))

                Spacer()
            }
            .frame(maxWidth: 420)
            .padding(28)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Excluded Apps Pane

struct ExcludedAppsPane: View {
    @EnvironmentObject var monitor: ClipboardMonitor
    @State private var excludedList: [String] = []
    @State private var showingAppList = false
    @State private var runningApps: [AppInfo] = []

    struct AppInfo: Identifiable {
        let id: String; let name: String; let icon: NSImage?
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Excluded Apps")
                    .font(.system(size: 20, weight: .bold))

                Text("Clipboard content from these apps won\u{2019}t be saved.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    if excludedList.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Image(systemName: "app.badge.checkmark").font(.system(size: 24)).foregroundStyle(.quaternary)
                                Text("No excluded apps").font(.system(size: 12)).foregroundStyle(.tertiary)
                            }.padding(.vertical, 24)
                            Spacer()
                        }
                    } else {
                        ForEach(excludedList, id: \.self) { bid in
                            HStack(spacing: 8) {
                                Image(systemName: "app.fill").foregroundStyle(.secondary).font(.system(size: 14))
                                Text(bid).font(.system(size: 12, design: .monospaced))
                                Spacer()
                                Button { removeExcluded(bid) } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                                }.buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            if bid != excludedList.last { Divider().padding(.leading, 34) }
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))

                Button {
                    loadRunningApps()
                    withAnimation(.easeInOut(duration: 0.2)) { showingAppList.toggle() }
                } label: {
                    Label(showingAppList ? "Hide" : "Add from Running Apps\u{2026}",
                          systemImage: showingAppList ? "chevron.up" : "plus.circle")
                }.controlSize(.small)

                if showingAppList {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(runningApps) { app in
                                Button {
                                    addExcluded(app.id)
                                    withAnimation { showingAppList = false }
                                } label: {
                                    HStack(spacing: 8) {
                                        if let icon = app.icon {
                                            Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                                        } else {
                                            Image(systemName: "app.fill").frame(width: 20, height: 20).foregroundStyle(.secondary)
                                        }
                                        Text(app.name).font(.system(size: 12))
                                        Spacer()
                                        Text(app.id).font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(.tertiary).lineLimit(1)
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 5).contentShape(Rectangle())
                                }.buttonStyle(.plain)
                                if app.id != runningApps.last?.id { Divider().padding(.leading, 40) }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()
            }
            .frame(maxWidth: 420)
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .onAppear { loadExcluded() }
    }

    private func loadExcluded() { excludedList = Array(monitor.excludedApps).sorted() }
    private func addExcluded(_ id: String) {
        var a = monitor.excludedApps; a.insert(id); monitor.excludedApps = a; loadExcluded()
    }
    private func removeExcluded(_ id: String) {
        var a = monitor.excludedApps; a.remove(id); monitor.excludedApps = a; loadExcluded()
    }
    private func loadRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .compactMap { a in guard let b = a.bundleIdentifier else { return nil }
                return AppInfo(id: b, name: a.localizedName ?? b, icon: a.icon)
            }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
