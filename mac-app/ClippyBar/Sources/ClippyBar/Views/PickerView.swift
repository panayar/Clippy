import SwiftUI

struct PickerView: View {
    /// Selection accent — vibrant magenta/pink, matches the requested mock.
    static let selectionPink = Color(red: 0.78, green: 0.32, blue: 0.86)
    static let selectionPinkDeep = Color(red: 0.66, green: 0.24, blue: 0.78)

    @EnvironmentObject var store: ClipboardStore
    @EnvironmentObject var monitor: ClipboardMonitor
    @State private var searchText = ""
    @State private var selectedIndex: Int = 0
    @State private var hoveredId: String?
    @State private var activeFilters: Set<ClipboardItem.ContentType> = []
    @State private var editingItem: ClipboardItem?
    @State private var editText: String = ""
    @State private var visibleItemIds: Set<String> = []
    @State private var suppressVisibilitySnap: Bool = false
    @State private var filtersVisible: Bool = true
    @State private var showClearAllConfirm: Bool = false
    @FocusState private var isEditFocused: Bool
    @Namespace private var chipNamespace

    private var filteredItems: [ClipboardItem] {
        store.search(query: searchText, typeFilters: activeFilters)
    }

    private var pinnedItems: [ClipboardItem] {
        filteredItems.filter { $0.isPinned }.sorted { lhs, rhs in
            // Oldest pins stay at the top; newly pinned items land at the
            // bottom of the pinned list. Fall back to timestamp for legacy
            // items that don't have a pinned_at.
            (lhs.pinnedAt ?? lhs.timestamp) < (rhs.pinnedAt ?? rhs.timestamp)
        }
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

            if filtersVisible {
                filterChips
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
        .environment(\.colorScheme, .dark)
        .onAppear {
            selectedIndex = pinnedItems.count
            searchText = ""
            visibleItemIds.removeAll()
        }
        .onChange(of: searchText) { _ in
            selectedIndex = pinnedItems.count
            visibleItemIds.removeAll()
        }
        .onChange(of: activeFilters) { _ in
            selectedIndex = pinnedItems.count
            visibleItemIds.removeAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarPickerShown)) { _ in
            selectedIndex = pinnedItems.count
            searchText = ""
            activeFilters = []
            visibleItemIds.removeAll()
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
        .onReceive(NotificationCenter.default.publisher(for: .clipBarClearAll)) { _ in
            // Don't trigger while editing — Backspace inside the editor would
            // otherwise compete with the shortcut.
            if editingItem == nil && !store.items.isEmpty {
                showClearAllConfirm = true
            }
        }
        .alert("Clear clipboard history?", isPresented: $showClearAllConfirm) {
            Button("Clear", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.clearAll()
                }
                selectedIndex = 0
                visibleItemIds.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all \(store.items.count) item\(store.items.count == 1 ? "" : "s"). Pinned items will also be removed.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipBarToggleFilters)) { _ in
            withAnimation(.easeInOut(duration: 0.18)) {
                filtersVisible.toggle()
                // When hiding, drop any active filters so the list isn't
                // silently filtered by an invisible control.
                if !filtersVisible { activeFilters = [] }
            }
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
            filterChip(label: "Images", icon: "photo", type: .image)
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
            .foregroundStyle(isActive ? Self.selectionPink : .secondary)
            .background {
                Capsule()
                    .fill(isActive ? Self.selectionPink.opacity(0.22) : Color.white.opacity(0.06))
                    .matchedGeometryEffect(id: type.rawValue, in: chipNamespace)
            }
            .overlay {
                Capsule()
                    .strokeBorder(isActive ? Self.selectionPink.opacity(0.55) : Color.clear, lineWidth: 1)
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
        // Compute the search/filter/group output ONCE per body re-evaluation.
        // Previously each row called globalIndexFor → orderedItems → re-ran the
        // search and filtering, costing O(N²) per render and stuttering visibly
        // once the history grew past a few dozen items.
        let pinned = pinnedItems
        let groups = groupedUnpinnedItems
        let ordered = pinned + groups.flatMap { $0.items }
        var indexMap: [String: Int] = [:]
        indexMap.reserveCapacity(ordered.count)
        for (i, item) in ordered.enumerated() { indexMap[item.id] = i }

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    // Pinned section
                    if !pinned.isEmpty {
                        sectionHeader("Pinned", color: .orange)

                        ForEach(pinned) { item in
                            itemRow(item: item, index: indexMap[item.id] ?? -1)
                                .id("pinned-\(item.id)")
                        }

                        Divider()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }

                    // Unpinned items grouped by day
                    ForEach(Array(groups.enumerated()), id: \.element.label) { _, group in
                        sectionHeader(group.label, color: .secondary)

                        ForEach(group.items) { item in
                            itemRow(item: item, index: indexMap[item.id] ?? -1)
                                .id(item.id)
                        }
                    }
                }
                .padding(6)
            }
            .onChange(of: selectedIndex) { newIndex in
                if let item = ordered[safe: newIndex] {
                    let scrollId = item.isPinned ? "pinned-\(item.id)" : item.id
                    suppressVisibilitySnap = true
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(scrollId, anchor: .center)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        suppressVisibilitySnap = false
                    }
                }
            }
        }
    }

    /// Called from row onAppear/onDisappear. If the user scrolled the
    /// selected row off-screen, snap the selection to the first row that
    /// is currently visible so the highlight always stays on-screen.
    private func snapSelectionIfHidden() {
        guard !suppressVisibilitySnap else { return }
        let items = orderedItems
        guard !items.isEmpty, !visibleItemIds.isEmpty else { return }
        guard let selectedItem = items[safe: selectedIndex] else { return }
        if visibleItemIds.contains(selectedItem.id) { return }
        if let firstVisibleIndex = items.firstIndex(where: { visibleItemIds.contains($0.id) }) {
            suppressVisibilitySnap = true
            selectedIndex = firstVisibleIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                suppressVisibilitySnap = false
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
                        tooltip: item.isPinned ? "Unpin" : "Pin",
                        onSelected: isSelected
                    ) {
                        hoveredId = nil
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.togglePin(item)
                        }
                        selectedIndex = globalIndexFor(item: item)
                    }

                    if item.contentType == .text || item.contentType == .link {
                        actionButton(
                            icon: "pencil",
                            color: .blue,
                            tooltip: "Edit",
                            onSelected: isSelected
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
                        tooltip: "Delete",
                        onSelected: isSelected
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
                    .fill(
                        LinearGradient(
                            colors: [Self.selectionPink, Self.selectionPinkDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else if isHovered {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.06))
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
        .onAppear {
            visibleItemIds.insert(item.id)
        }
        .onDisappear {
            visibleItemIds.remove(item.id)
            snapSelectionIfHidden()
        }
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin") {
                hoveredId = nil
                store.togglePin(item)
                selectedIndex = globalIndexFor(item: item)
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
        ItemThumbnail(item: item)

        VStack(alignment: .leading, spacing: 2) {
            Text(itemTitle(for: item))
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            timestampRow(item: item)
        }
    }

    private func itemTitle(for item: ClipboardItem) -> String {
        switch item.contentType {
        case .image:
            return "Image"
        case .file, .text, .link:
            return item.preview(maxLength: 140)
        }
    }

    private func actionButton(
        icon: String,
        color: Color,
        tooltip: String,
        onSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        // On the pink-selected row, swap the colored chip for a clean
        // white-on-glass look so the buttons read clearly against the
        // strong magenta background. Off-selection, keep the per-action
        // tint (orange/blue/red) for affordance.
        let foreground: Color = onSelected ? .white : color.opacity(0.85)
        let fill: Color = onSelected ? Color.white.opacity(0.22) : color.opacity(0.12)

        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 22, height: 22)
                .background(fill, in: RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white.opacity(onSelected ? 0.18 : 0), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    private func timestampRow(item: ClipboardItem) -> some View {
        HStack(spacing: 4) {
            Text(typeLabel(for: item))
            Text("\u{00B7}")
            Text("Copied \(item.relativeTimestamp)")
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
    }

    private func typeLabel(for item: ClipboardItem) -> String {
        switch item.contentType {
        case .text: return "Text"
        case .link: return "Link"
        case .file: return "File"
        case .image: return "Image"
        }
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
                kbHint(keys: ["\u{2318}\u{21E7}\u{232B}"], label: "clear")
            }
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    private func kbHint(keys: [String], label: String) -> some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.12))
                    )
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
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
        selectedIndex = globalIndexFor(item: item)
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { closeEditor() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.55))
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }

                ScrollableTextEditor(text: $editText)
                    .frame(minHeight: 120, maxHeight: 220)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                HStack(spacing: 10) {
                    Text("\(editText.count) characters")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Spacer(minLength: 8)

                    Button("Cancel") {
                        closeEditor()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .fixedSize()

                    Button(action: { saveEdit(for: item) }) {
                        Text("Save")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(
                                LinearGradient(
                                    colors: [Self.selectionPink, Self.selectionPinkDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: Capsule()
                            )
                            .shadow(color: Self.selectionPinkDeep.opacity(0.4), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1.0)
                    .fixedSize()
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.12).opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
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

// MARK: - Item Thumbnail (uniform 32×32 with source-app badge)

/// Fixed-size leading icon for every clipboard row. Renders a generic
/// content-type icon (or an image thumbnail) and overlays the source
/// app's icon as a small badge in the bottom-right corner.
private struct ItemThumbnail: View {
    let item: ClipboardItem
    @State private var image: NSImage?

    private static let size: CGFloat = 32

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            base
                .frame(width: Self.size, height: Self.size)

            if let appIcon = SourceAppIconResolver.shared.icon(for: item.sourceApp) {
                Image(nsImage: appIcon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
                    .background(
                        Circle().fill(Color.black.opacity(0.35))
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .offset(x: 3, y: 3)
            }
        }
        .frame(width: Self.size + 4, height: Self.size + 4, alignment: .center)
        .onAppear {
            if item.contentType == .image {
                item.loadImageAsync { loaded in image = loaded }
            }
        }
    }

    @ViewBuilder
    private var base: some View {
        switch item.contentType {
        case .image:
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.06))
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Self.size, height: Self.size)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        case .file, .text, .link:
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.06))
                Image(systemName: glyph)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
        }
    }

    private var glyph: String {
        switch item.contentType {
        case .text: return "doc.text"
        case .link: return "link"
        case .file: return "doc"
        case .image: return "photo"
        }
    }
}

// MARK: - Source App Icon Resolver

/// Resolves a clipboard item's source-app name to its NSImage icon.
/// Looks up running applications by localizedName and caches the result.
@MainActor
private final class SourceAppIconResolver {
    static let shared = SourceAppIconResolver()

    private var cache: [String: NSImage] = [:]
    private var negativeCache: Set<String> = []

    private init() {}

    func icon(for appName: String?) -> NSImage? {
        guard let name = appName, !name.isEmpty else { return nil }
        if let cached = cache[name] { return cached }
        if negativeCache.contains(name) { return nil }

        if let running = NSWorkspace.shared.runningApplications
            .first(where: { $0.localizedName == name }),
           let icon = running.icon {
            cache[name] = icon
            return icon
        }

        // Fallback: try locating the app bundle by name.  fullPath is
        // deprecated but still works on every supported macOS version
        // and is the simplest cross-version lookup.
        if let path = NSWorkspace.shared.fullPath(forApplication: name) {
            let icon = NSWorkspace.shared.icon(forFile: path)
            cache[name] = icon
            return icon
        }

        negativeCache.insert(name)
        return nil
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
