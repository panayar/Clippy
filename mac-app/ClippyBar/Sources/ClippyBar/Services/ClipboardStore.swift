import Foundation
import SQLite3
import SwiftUI

// SQLite transient destructor — tells SQLite to copy the string immediately
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Wrapper so we can pass OpaquePointer? into @Sendable closures.
/// Safety: all access is serialized through ClipboardStore.dbQueue.
private struct SendableDBPointer: @unchecked Sendable {
    let pointer: OpaquePointer?
}

@MainActor
final class ClipboardStore: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private var db: OpaquePointer?
    private let dbPath: String
    private let imagesDir: URL

    /// Serial queue for ALL SQLite I/O — keeps the main thread free.
    private let dbQueue = DispatchQueue(label: "com.clipbar.database", qos: .userInitiated)

    @AppStorage("itemLimit") var itemLimit: Int = 50
    @AppStorage("retentionDays") var retentionDays: Int = 7  // 0 = forever
    @AppStorage("memoryOnlyMode") var memoryOnlyMode: Bool = false

    init() {
        guard let appSupportBase = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            // Fallback to temp directory — app runs in memory-only mode
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("ClippyBar", isDirectory: true)
            try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
            imagesDir = tmp.appendingPathComponent("images", isDirectory: true)
            try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            dbPath = tmp.appendingPathComponent("clipboard.db").path
            print("[ClippyBar] Warning: Application Support unavailable, using temp directory")
            openDatabase()
            createTableIfNeeded()
            loadItems()
            pruneExpiredItems()
            return
        }
        let appSupport = appSupportBase.appendingPathComponent("ClippyBar", isDirectory: true)

        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)

        imagesDir = appSupport.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        dbPath = appSupport.appendingPathComponent("clipboard.db").path
        openDatabase()
        createTableIfNeeded()
        loadItems()
        pruneExpiredItems()
    }

    deinit {
        // sqlite3_close is thread-safe — safe to call from deinit
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            if let db = db {
                print("[ClippyBar] DB open error: \(String(cString: sqlite3_errmsg(db)))")
            }
            db = nil
        }
    }

    private func createTableIfNeeded() {
        guard let db = db else { return }
        let sql = """
            CREATE TABLE IF NOT EXISTS clipboard_items (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                content_type TEXT NOT NULL DEFAULT 'text',
                timestamp REAL NOT NULL,
                is_pinned INTEGER NOT NULL DEFAULT 0,
                source_app TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_timestamp ON clipboard_items(timestamp);
            """
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg = errMsg {
                print("[ClippyBar] Table error: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
        }
    }

    // MARK: - CRUD

    private func loadItems() {
        guard let db = db, !memoryOnlyMode else { return }

        let sql = "SELECT id, content, content_type, timestamp, is_pinned, source_app FROM clipboard_items ORDER BY timestamp DESC;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        var loaded: [ClipboardItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idPtr = sqlite3_column_text(stmt, 0),
                  let contentPtr = sqlite3_column_text(stmt, 1),
                  let typePtr = sqlite3_column_text(stmt, 2) else { continue }

            let id = String(cString: idPtr)
            let content = String(cString: contentPtr)
            let contentTypeRaw = String(cString: typePtr)
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 3))
            let isPinned = sqlite3_column_int(stmt, 4) != 0
            let sourceApp: String? = sqlite3_column_text(stmt, 5).map { String(cString: $0) }

            loaded.append(ClipboardItem(
                id: id,
                content: content,
                contentType: ClipboardItem.ContentType(rawValue: contentTypeRaw) ?? .text,
                timestamp: timestamp,
                isPinned: isPinned,
                sourceApp: sourceApp
            ))
        }
        items = loaded
    }

    func addItem(_ item: ClipboardItem) {
        // Deduplicate: remove existing item with same content
        var imageFileToDelete: String?
        var dbIdToDelete: String?
        var itemToInsert = item

        // Short-circuit with count check (O(1)) before full string compare (O(n)).
        // For 200 items of 50K chars each, this avoids ~200 expensive comparisons.
        let newCount = item.content.count
        if let existingIndex = items.firstIndex(where: {
            $0.contentType == item.contentType
            && $0.content.count == newCount
            && $0.content == item.content
        }) {
            let existing = items[existingIndex]
            dbIdToDelete = existing.id
            // Preserve pin status when a pinned item's content is re-copied
            if existing.isPinned {
                itemToInsert = ClipboardItem(
                    id: item.id,
                    content: item.content,
                    contentType: item.contentType,
                    timestamp: item.timestamp,
                    isPinned: true,
                    sourceApp: item.sourceApp
                )
            }
            if existing.contentType == .image {
                imageFileToDelete = existing.content
            }
            items.remove(at: existingIndex)
        }

        items.insert(itemToInsert, at: 0)

        // Collect evicted items before modifying `items` further
        var evictedDBIds: [String] = []
        var evictedImageFiles: [String] = []

        // Evict items older than retention period (pinned items are exempt)
        if retentionDays > 0 {
            let cutoff = Date().addingTimeInterval(-Double(retentionDays) * 86400)
            items.removeAll { item in
                guard !item.isPinned, item.timestamp < cutoff else { return false }
                evictedDBIds.append(item.id)
                if item.contentType == .image { evictedImageFiles.append(item.content) }
                return true
            }
        }

        // Evict by item count limit (pinned items are exempt from the count)
        while items.filter({ !$0.isPinned }).count > itemLimit {
            if let lastNonPinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                let removed = items.remove(at: lastNonPinnedIndex)
                evictedDBIds.append(removed.id)
                if removed.contentType == .image {
                    evictedImageFiles.append(removed.content)
                }
            } else {
                break
            }
        }

        // Dispatch ALL SQLite + file I/O to the background queue
        let dbPtr = SendableDBPointer(pointer: self.db)
        let memOnly = self.memoryOnlyMode
        let imgDir = self.imagesDir

        dbQueue.async {
            let capturedDB = dbPtr.pointer
            // Delete duplicate from DB
            if let deleteId = dbIdToDelete {
                Self.deleteFromDB(db: capturedDB, memoryOnly: memOnly, id: deleteId)
            }
            // Clean up duplicate image file
            if let imgFile = imageFileToDelete {
                Self.deleteImageFile(imagesDir: imgDir, fileName: imgFile)
            }
            // Insert the new item (may carry over pin status from duplicate)
            Self.insertIntoDB(db: capturedDB, memoryOnly: memOnly, item: itemToInsert)
            // Evict over-limit items
            for id in evictedDBIds {
                Self.deleteFromDB(db: capturedDB, memoryOnly: memOnly, id: id)
            }
            for imgFile in evictedImageFiles {
                Self.deleteImageFile(imagesDir: imgDir, fileName: imgFile)
            }
        }
    }

    /// Remove non-pinned items older than the retention period.
    /// Called once on launch to clean up stale history.
    func pruneExpiredItems() {
        guard retentionDays > 0 else { return }
        let cutoff = Date().addingTimeInterval(-Double(retentionDays) * 86400)

        var expiredIds: [String] = []
        var expiredImages: [String] = []
        items.removeAll { item in
            guard !item.isPinned, item.timestamp < cutoff else { return false }
            expiredIds.append(item.id)
            if item.contentType == .image { expiredImages.append(item.content) }
            return true
        }

        guard !expiredIds.isEmpty else { return }

        let dbPtr = SendableDBPointer(pointer: self.db)
        let memOnly = self.memoryOnlyMode
        let imgDir = self.imagesDir
        dbQueue.async {
            for id in expiredIds {
                Self.deleteFromDB(db: dbPtr.pointer, memoryOnly: memOnly, id: id)
            }
            for imgFile in expiredImages {
                Self.deleteImageFile(imagesDir: imgDir, fileName: imgFile)
            }
        }
    }

    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        let dbPtr = SendableDBPointer(pointer: self.db)
        let memOnly = self.memoryOnlyMode
        let imgDir = self.imagesDir
        let isImage = item.contentType == .image
        let content = item.content
        let itemId = item.id
        dbQueue.async {
            Self.deleteFromDB(db: dbPtr.pointer, memoryOnly: memOnly, id: itemId)
            if isImage {
                Self.deleteImageFile(imagesDir: imgDir, fileName: content)
            }
        }
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        let newPinned = items[index].isPinned
        let dbPtr = SendableDBPointer(pointer: self.db)
        let memOnly = self.memoryOnlyMode
        let itemId = item.id
        dbQueue.async {
            Self.updatePinInDB(db: dbPtr.pointer, memoryOnly: memOnly, id: itemId, isPinned: newPinned)
        }
    }

    func updateItemContent(_ item: ClipboardItem, newContent: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let updated = ClipboardItem(
            id: item.id,
            content: newContent,
            contentType: ClipboardItem.looksLikeURL(newContent) ? .link : .text,
            timestamp: item.timestamp,
            isPinned: item.isPinned,
            sourceApp: item.sourceApp
        )
        items[index] = updated

        let dbPtr = SendableDBPointer(pointer: self.db)
        let memOnly = self.memoryOnlyMode
        dbQueue.async {
            Self.insertIntoDB(db: dbPtr.pointer, memoryOnly: memOnly, item: updated)
        }
    }

    func clearAll() {
        let imageFiles = items.compactMap { $0.contentType == .image ? $0.content : nil }
        items.removeAll()
        let dbPtr = SendableDBPointer(pointer: self.db)
        let memOnly = self.memoryOnlyMode
        let imgDir = self.imagesDir
        dbQueue.async {
            Self.clearDB(db: dbPtr.pointer, memoryOnly: memOnly)
            for imgFile in imageFiles {
                Self.deleteImageFile(imagesDir: imgDir, fileName: imgFile)
            }
        }
    }

    /// Move an item to the top of the list with an updated timestamp.
    /// Called when a user pastes an item so it's easy to find again.
    func touchItem(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = items.remove(at: index)
        let newTimestamp = Date()

        // Rebuild item with new timestamp (ClipboardItem fields are let)
        updated = ClipboardItem(
            id: updated.id,
            content: updated.content,
            contentType: updated.contentType,
            timestamp: newTimestamp,
            isPinned: updated.isPinned,
            sourceApp: updated.sourceApp
        )
        items.insert(updated, at: 0)

        // Update timestamp in DB
        let dbPtr = SendableDBPointer(pointer: self.db)
        let memOnly = self.memoryOnlyMode
        let itemId = updated.id
        let ts = newTimestamp.timeIntervalSince1970
        dbQueue.async {
            guard let db = dbPtr.pointer, !memOnly else { return }
            let sql = "UPDATE clipboard_items SET timestamp = ? WHERE id = ?;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_double(stmt, 1, ts)
            sqlite3_bind_text(stmt, 2, itemId, -1, SQLITE_TRANSIENT)
            sqlite3_step(stmt)
        }
    }

    func search(query: String, typeFilters: Set<ClipboardItem.ContentType> = []) -> [ClipboardItem] {
        var result = items

        if !typeFilters.isEmpty {
            result = result.filter { typeFilters.contains($0.contentType) }
        }

        if !query.isEmpty {
            result = result.filter {
                switch $0.contentType {
                case .text, .link:
                    return $0.content.range(of: query, options: .caseInsensitive) != nil
                case .file:
                    return ($0.content as NSString).lastPathComponent.range(of: query, options: .caseInsensitive) != nil
                case .image:
                    return "image".range(of: query, options: .caseInsensitive) != nil
                }
            }
        }

        return result
    }

    // MARK: - Image File Management (static, called from background queue)

    private nonisolated static func deleteImageFile(imagesDir: URL, fileName: String) {
        let filePath = imagesDir.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: filePath)
    }

    // MARK: - SQLite Helpers (static, thread-safe, called from dbQueue)

    private nonisolated static func insertIntoDB(db: OpaquePointer?, memoryOnly: Bool, item: ClipboardItem) {
        guard let db = db, !memoryOnly else { return }

        let sql = "INSERT OR REPLACE INTO clipboard_items (id, content, content_type, timestamp, is_pinned, source_app) VALUES (?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, item.id, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, item.content, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, item.contentType.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 4, item.timestamp.timeIntervalSince1970)
        sqlite3_bind_int(stmt, 5, item.isPinned ? 1 : 0)
        if let app = item.sourceApp {
            sqlite3_bind_text(stmt, 6, app, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 6)
        }

        sqlite3_step(stmt)
    }

    private nonisolated static func deleteFromDB(db: OpaquePointer?, memoryOnly: Bool, id: String) {
        guard let db = db, !memoryOnly else { return }
        let sql = "DELETE FROM clipboard_items WHERE id = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, id, -1, SQLITE_TRANSIENT)
        sqlite3_step(stmt)
    }

    private nonisolated static func updatePinInDB(db: OpaquePointer?, memoryOnly: Bool, id: String, isPinned: Bool) {
        guard let db = db, !memoryOnly else { return }
        let sql = "UPDATE clipboard_items SET is_pinned = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, isPinned ? 1 : 0)
        sqlite3_bind_text(stmt, 2, id, -1, SQLITE_TRANSIENT)
        sqlite3_step(stmt)
    }

    private nonisolated static func clearDB(db: OpaquePointer?, memoryOnly: Bool) {
        guard let db = db, !memoryOnly else { return }
        var errMsg: UnsafeMutablePointer<CChar>?
        sqlite3_exec(db, "DELETE FROM clipboard_items;", nil, nil, &errMsg)
        if let errMsg = errMsg { sqlite3_free(errMsg) }
    }
}
