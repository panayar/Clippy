import SwiftUI

/// The dropdown view shown when clicking the menu bar icon.
struct MenuBarView: View {
    @EnvironmentObject var store: ClipboardStore
    @EnvironmentObject var monitor: ClipboardMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
            recentItemsSection
            Divider()
            actionsSection
        }
        .frame(width: 300)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("ClippyBar")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if monitor.isPaused {
                Text("Paused")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
            Text("\(store.items.count) items")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Recent Items

    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.items.isEmpty {
                Text("No clipboard history yet")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(store.items.prefix(5))) { item in
                    Button {
                        copyItem(item)
                    } label: {
                        HStack(spacing: 6) {
                            if item.isPinned {
                                Image(systemName: "pin.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 9))
                            }
                            Text(item.preview(maxLength: 50))
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer()
                            Text(item.relativeTimestamp)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                PickerWindowController.shared.show()
            } label: {
                Label("Show Clipboard History", systemImage: "list.clipboard")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                monitor.isPaused.toggle()
            } label: {
                Label(
                    monitor.isPaused ? "Resume History" : "Pause History",
                    systemImage: monitor.isPaused ? "play.fill" : "pause.fill"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            Button {
                store.clearAll()
                monitor.resetChangeCount()
            } label: {
                Label("Clear History", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                openSettings()
            } label: {
                Label("Settings\u{2026}", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit ClippyBar", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func copyItem(_ item: ClipboardItem) {
        monitor.skipNextChange = true
        let pb = NSPasteboard.general
        pb.clearContents()

        if item.contentType == .image, let img = item.loadImage(),
           let tiffData = img.tiffRepresentation {
            pb.setData(tiffData, forType: .tiff)
        } else {
            pb.setString(item.content, forType: .string)
        }
    }

    private func openSettings() {
        SettingsWindowController.shared.show()
    }
}
