import SwiftUI

struct PickerView: View {
    @EnvironmentObject var store: ClipboardStore
    @EnvironmentObject var monitor: ClipboardMonitor
    @State private var searchText = ""
    @State private var selectedIndex: Int = 0
    @State private var hoveredId: String?
    @State private var activeFilters: Set<ClipboardItem.ContentType> = []
    @State private var editingItem: ClipboardItem?
    @State private var editText: String = ""
    @FocusState private var isEditFocused: Bool
    @Namespace private var chipNamespace

    private var filteredItems: [ClipboardItem] {
        store.search(query: searchText, typeFilters: activeFilters)
    }

    private var pinnedItems: [ClipboardItem] {
        filteredItems.filter { $0.isPinned }
    }

    private var unpinnedItems: [ClipboardItem] {
        filteredItems.filter { !$0.isPinned }
    }

    /// Groups unpinned items by day for section headers
    private var groupedUnpinnedItems: [(label: String, items: [ClipboardItem])] {
        let calendar = Calendar.current
        let now = Date()
        var groups: [(label: String, items: [ClipboardItem])] = []
        var currentLabel = ""
        var currentItems: [ClipboardItem] = []

        for item in unpinnedItems {
            let label = Self.dayLabel(for: item.timestamp, now: now, calendar: calendar)
            if label != currentLabel {
                if !currentItems.isEmpty {
                    groups.append((label: currentLabel, items: currentItems))
                }
                currentLabel = label
                currentItems = [item]
            } else {
                currentItems.append(item)
            }
        }
        if !currentItems.isEmpty {
            groups.append((label: currentLabel, items: currentItems))
        }
        return groups
    }

    private static func dayLabel(for date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // e.g. "Monday"
            return formatter.string(from: date)
        }

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM d" // e.g. "Mar 28"
        return monthFormatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 28)

            searchBar
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            filterChips
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            Divider().opacity(0.3)

            if filteredItems.isEmpty {
                emptyState
            } else {
                itemListView
            }

            Divider().opacity(0.3)
            statusBar
        }
        .background(.clear)
        .onAppear {
            selectedIndex = pinnedItems.count
            searchText = ""
        }
        .onChange(of: searchText) { _ in
            selectedIndex = pinnedItems.count
        }
        .onChange(of: activeFilters) { _ in
            selectedIndex = pinnedItems.count
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarPickerShown)) { _ in
            selectedIndex = pinnedItems.count
            searchText = ""
            activeFilters = []
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarMoveUp)) { _ in
            moveSelection(by: -1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarMoveDown)) { _ in
            moveSelection(by: 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarSelect)) { _ in
            selectCurrentItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarDelete)) { _ in
            deleteSelectedItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarTogglePin)) { _ in
            pinSelectedItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarEditItem)) { _ in
            editSelectedItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarSaveEdit)) { _ in
            if let item = editingItem { saveEdit(for: item) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarCancelEdit)) { _ in
            closeEditor()
        }
        .overlay {
            if let item = editingItem {
                editOverlay(for: item)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13, weight: .medium))

            TextField("Search\u{2026}", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .onSubmit { selectCurrentItem() }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.quaternary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: 6) {
            filterChip(label: "Text", icon: "doc.text", type: .text)
            filterChip(label: "Links", icon: "link", type: .link)
            filterChip(label: "Files", icon: "doc.fill", type: .file)
            Spacer()
        }
    }

    private func filterChip(label: String, icon: String, type: ClipboardItem.ContentType) -> some View {
        let isActive = activeFilters.contains(type)
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                if isActive {
                    activeFilters.remove(type)
                } else {
                    activeFilters.insert(type)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, isActive ? 12 : 10)
            .padding(.vertical, 5)
            .foregroundStyle(isActive ? Color.accentColor : .secondary)
            .background {
                Capsule()
                    .fill(isActive ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05))
                    .matchedGeometryEffect(id: type.rawValue, in: chipNamespace)
            }
            .overlay {
                Capsule()
                    .strokeBorder(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            }
            .scaleEffect(isActive ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(.quaternary)
            Text(searchText.isEmpty ? "No items yet" : "No results")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Copy something to see it here")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Item List

    /// Ordered list: pinned first, then unpinned — used for keyboard navigation
    private var orderedItems: [ClipboardItem] {
        pinnedItems + unpinnedItems
    }

    /// Default selection: first item
    private var defaultSelectionIndex: Int {
        orderedItems.isEmpty ? -1 : 0
    }

    private var itemListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    // Pinned section
                    if !pinnedItems.isEmpty {
                        sectionHeader("Pinned", color: .orange)

                        ForEach(pinnedItems) { item in
                            let globalIndex = globalIndexFor(item: item)
                            itemRow(item: item, index: globalIndex)
                                .id("pinned-\(item.id)")
                        }

                        Divider()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }

                    // Unpinned items grouped by day
                    let groups = groupedUnpinnedItems
                    ForEach(Array(groups.enumerated()), id: \.element.label) { groupIndex, group in
                        sectionHeader(group.label, color: .secondary)

                        ForEach(group.items) { item in
                            let globalIndex = globalIndexFor(item: item)
                            itemRow(item: item, index: globalIndex)
                                .id(item.id)
                        }
                    }
                }
                .padding(6)
            }
            .onChange(of: selectedIndex) { newIndex in
                if let item = orderedItems[safe: newIndex] {
                    let scrollId = item.isPinned ? "pinned-\(item.id)" : item.id
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(scrollId, anchor: .center)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    /// Maps an item back to its index in orderedItems for keyboard navigation
    private func globalIndexFor(item: ClipboardItem) -> Int {
        orderedItems.firstIndex(where: { $0.id == item.id }) ?? -1
    }

    // MARK: - Item Row

    private func itemRow(item: ClipboardItem, index: Int) -> some View {
        let isSelected = index == selectedIndex
        let isHovered = hoveredId == item.id

        return HStack(spacing: 8) {
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 10))
                    .frame(width: 14)
            } else {
                Color.clear.frame(width: 14, height: 1)
            }

            itemContent(item: item)

            Spacer(minLength: 4)

            // Action buttons — visible on hover only
            if isHovered {
                HStack(spacing: 4) {
                    actionButton(
                        icon: item.isPinned ? "pin.slash.fill" : "pin.fill",
                        color: .orange,
                        tooltip: item.isPinned ? "Unpin" : "Pin"
                    ) {
                        hoveredId = nil
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.togglePin(item)
                        }
                        selectedIndex = pinnedItems.count
                    }

                    if item.contentType == .text || item.contentType == .link {
                        actionButton(
                            icon: "pencil",
                            color: .blue,
                            tooltip: "Edit"
                        ) {
                            editText = item.content
                            editingItem = item
                            PickerWindowController.shared.isEditing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isEditFocused = true
                            }
                        }
                    }

                    actionButton(
                        icon: "trash.fill",
                        color: .red,
                        tooltip: "Delete"
                    ) {
                        hoveredId = nil
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.deleteItem(item)
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.18))
            } else if isHovered {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.04))
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredId = hovering ? item.id : nil
            }
        }
        .onTapGesture {
            selectedIndex = index
            selectCurrentItem()
        }
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin") {
                hoveredId = nil
                store.togglePin(item)
                selectedIndex = pinnedItems.count
            }
            if item.contentType == .text || item.contentType == .link {
                Button("Edit") {
                    editText = item.content
                    editingItem = item
                    PickerWindowController.shared.isEditing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isEditFocused = true
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.deleteItem(item)
            }
        }
    }

    @ViewBuilder
    private func itemContent(item: ClipboardItem) -> some View {
        switch item.contentType {
        case .image:
            AsyncImageThumbnail(item: item)
            VStack(alignment: .leading, spacing: 2) {
                Text("Image")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                timestampRow(item: item)
            }
        case .file:
            Image(systemName: "doc.fill")
                .font(.system(size: 18))
                .foregroundStyle(.blue.opacity(0.7))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview(maxLength: 120))
                    .font(.system(size: 13))
                    .lineLimit(1)
                timestampRow(item: item)
            }
        case .link:
            Image(systemName: "link")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.blue.opacity(0.7))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview(maxLength: 120))
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
                    .lineLimit(2)
                timestampRow(item: item)
            }
        case .text:
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview(maxLength: 120))
                    .font(.system(size: 13))
                    .lineLimit(2)
                timestampRow(item: item)
            }
        }
    }

    private func actionButton(icon: String, color: Color, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color.opacity(0.7))
                .frame(width: 22, height: 22)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    private func timestampRow(item: ClipboardItem) -> some View {
        HStack(spacing: 4) {
            Text(item.relativeTimestamp)
            if let app = item.sourceApp {
                Text("\u{00B7}")
                Text(app)
            }
        }
        .font(.system(size: 10))
        .foregroundStyle(.tertiary)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text("\(store.items.count) items")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

            if monitor.isPaused {
                Text("Paused")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.orange.opacity(0.12), in: Capsule())
            }

            Spacer()

            HStack(spacing: 10) {
                kbHint(keys: ["\u{2191}\u{2193}"], label: "navigate")
                kbHint(keys: ["\u{21A9}\u{FE0E}"], label: "paste")
                kbHint(keys: ["\u{2318}P"], label: "pin")
                kbHint(keys: ["\u{2318}E"], label: "edit")
                kbHint(keys: ["\u{2318}\u{232B}"], label: "delete")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    private func kbHint(keys: [String], label: String) -> some View {
        HStack(spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(.quaternary))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Navigation

    private func moveSelection(by offset: Int) {
        let count = orderedItems.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(selectedIndex + offset, count - 1))
    }

    // MARK: - Actions

    private func deleteSelectedItem() {
        let items = orderedItems
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        let item = items[selectedIndex]
        hoveredId = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            store.deleteItem(item)
        }
        if selectedIndex >= orderedItems.count {
            selectedIndex = max(0, orderedItems.count - 1)
        }
    }

    private func pinSelectedItem() {
        let items = orderedItems
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        let item = items[selectedIndex]
        withAnimation(.easeInOut(duration: 0.2)) {
            store.togglePin(item)
        }
        // After pinning/unpinning, move selection to the first unpinned item
        // so pinned items don't remain visually selected
        selectedIndex = pinnedItems.count
    }

    private func editSelectedItem() {
        let items = orderedItems
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        let item = items[selectedIndex]
        guard item.contentType == .text || item.contentType == .link else { return }
        editText = item.content
        editingItem = item
        PickerWindowController.shared.isEditing = true
        // Focus the editor after a brief delay so SwiftUI lays out the overlay first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isEditFocused = true
        }
    }

    private func saveEdit(for item: ClipboardItem) {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.updateItemContent(item, newContent: editText)
        }
        closeEditor()
    }

    private func closeEditor() {
        editingItem = nil
        isEditFocused = false
        PickerWindowController.shared.isEditing = false
    }

    // MARK: - Edit Overlay

    private func editOverlay(for item: ClipboardItem) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { closeEditor() }

            VStack(spacing: 12) {
                HStack {
                    Text("Edit Item")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Button(action: { closeEditor() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }

                ScrollableTextEditor(text: $editText)
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Text("\(editText.count) characters")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Text("\u{21A9}\u{FE0E} save  \u{238B} cancel")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Button("Cancel") {
                        closeEditor()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))

                    Button(action: { saveEdit(for: item) }) {
                        Text("Save")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.accentColor, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
        .transition(.opacity)
    }

    private func selectCurrentItem() {
        let items = orderedItems
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        let item = items[selectedIndex]

        // Move item to top so it's easy to find again
        store.touchItem(item)
        monitor.skipNextChange = true

        let autoPaste = UserDefaults.standard.object(forKey: "autoPasteEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "autoPasteEnabled")

        switch item.contentType {
        case .image:
            item.loadImageAsync { img in
                let pb = NSPasteboard.general
                pb.clearContents()
                if let img = img, let tiffData = img.tiffRepresentation {
                    pb.setData(tiffData, forType: .tiff)
                    if let bmp = NSBitmapImageRep(data: tiffData),
                       let pngData = bmp.representation(using: .png, properties: [:]) {
                        pb.setData(pngData, forType: .png)
                    }
                }
                PickerWindowController.shared.hideAndRestoreFocus()
                if autoPaste {
                    AutoPaster.pasteAfterDelay(milliseconds: 350)
                }
            }
        case .file:
            let fileURL = URL(fileURLWithPath: item.content)
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.writeObjects([fileURL as NSURL])
            PickerWindowController.shared.hideAndRestoreFocus()
            if autoPaste {
                AutoPaster.pasteAfterDelay(milliseconds: 200)
            }
        case .text, .link:
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(item.content, forType: .string)
            PickerWindowController.shared.hideAndRestoreFocus()
            if autoPaste {
                AutoPaster.pasteAfterDelay(milliseconds: 200)
            }
        }
    }
}

// MARK: - Async Image Thumbnail

private struct AsyncImageThumbnail: View {
    let item: ClipboardItem
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 60, maxHeight: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 60, height: 40)
            }
        }
        .onAppear {
            item.loadImageAsync { loaded in
                image = loaded
            }
        }
    }
}

// MARK: - Scrollable Text Editor (NSTextView wrapper)

/// NSTextView-backed editor that scrolls to the end and places the cursor
/// at the end of the text on appear, so long content is immediately editable.
private struct ScrollableTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.delegate = context.coordinator

        scrollView.documentView = textView

        // Set initial text, move cursor to end, scroll to end
        textView.string = text
        let endPos = text.count
        textView.setSelectedRange(NSRange(location: endPos, length: 0))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            textView.scrollToEndOfDocument(nil)
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            let sel = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(sel)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScrollableTextEditor

        init(_ parent: ScrollableTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// MARK: - Safe subscript

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
