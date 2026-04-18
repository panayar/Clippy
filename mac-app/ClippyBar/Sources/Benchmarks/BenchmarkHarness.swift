import ClippyBarCore
import Foundation
import SQLite3

/// Deterministic PRNG — pinned seed so workloads reproduce exactly.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xdeadbeef : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// A content profile that roughly matches real clipboard distributions:
/// 80% short (< 200 chars), 15% medium (< 2k), 5% near the 50k cap.
enum ContentProfile {
    static func generate(count: Int, seed: UInt64 = 42) -> [String] {
        var rng = SeededGenerator(seed: seed)
        var out: [String] = []
        out.reserveCapacity(count)
        for i in 0..<count {
            let bucket = Int.random(in: 0..<100, using: &rng)
            let length: Int
            if bucket < 80 {
                length = Int.random(in: 10...200, using: &rng)
            } else if bucket < 95 {
                length = Int.random(in: 200...2000, using: &rng)
            } else {
                length = Int.random(in: 20_000...50_000, using: &rng)
            }
            // Prefix with index so items are unique but have realistic bulk.
            out.append("item-\(i)-" + String(repeating: "x", count: max(0, length - 8)))
        }
        return out
    }
}

/// Creates a fresh isolated storage directory for each benchmark iteration.
/// Caller is responsible for cleaning up via `destroy()`.
final class IsolatedStorage {
    let directory: URL

    init() {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("clippy-bench-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        self.directory = tmp
    }

    func destroy() {
        try? FileManager.default.removeItem(at: directory)
    }
}

/// Build a store pre-populated with `count` unique items drawn from the content profile.
/// Waits for all background writes to drain before returning so timing is
/// deterministic.
@MainActor
func makePopulatedStore(directory: URL, count: Int, seed: UInt64 = 42) -> ClipboardStore {
    let store = ClipboardStore(storageDirectory: directory)
    store.configureForBenchmarking(itemLimit: max(count * 2, 1000), retentionDays: 0)
    let contents = ContentProfile.generate(count: count, seed: seed)
    for content in contents {
        store.addItem(ClipboardItem(content: content))
    }
    store.waitForPendingWrites()
    return store
}

/// SQLite transient destructor — mirrors the one in ClipboardStore.
private let BENCH_SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Fast-path seed: writes `count` rows directly into the DB via a single
/// transaction, bypassing `addItem`'s dedup scan and dispatch layer.
/// Used by scenarios that want a pre-populated DB without the per-item
/// setup cost.
///
/// Schema must stay in sync with `ClipboardStore.createTableIfNeeded`.
func seedDatabaseDirectly(at directory: URL, count: Int, seed: UInt64 = 42) {
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(
        at: directory.appendingPathComponent("images", isDirectory: true),
        withIntermediateDirectories: true
    )
    let dbPath = directory.appendingPathComponent("clipboard.db").path

    var db: OpaquePointer?
    guard sqlite3_open(dbPath, &db) == SQLITE_OK, let db else { return }
    defer { sqlite3_close(db) }

    // Match the production ClipboardStore's pragma setup so the benchmark
    // store isn't paying one-time WAL setup cost inside the measured section.
    sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil)
    sqlite3_exec(db, "PRAGMA synchronous = NORMAL;", nil, nil, nil)

    let createSQL = """
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
    sqlite3_exec(db, createSQL, nil, nil, nil)

    sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
    let insertSQL = "INSERT INTO clipboard_items (id, content, content_type, timestamp, is_pinned, source_app) VALUES (?, ?, 'text', ?, 0, NULL);"
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
        sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
        return
    }
    defer { sqlite3_finalize(stmt) }

    let contents = ContentProfile.generate(count: count, seed: seed)
    // Spread timestamps across a week so retention-based scenarios can exercise
    // expiry realistically without every row being "now".
    let now = Date().timeIntervalSince1970
    let spread: Double = 7 * 86400
    for (i, content) in contents.enumerated() {
        let id = UUID().uuidString
        let ts = now - (Double(i) / Double(max(count - 1, 1))) * spread
        sqlite3_bind_text(stmt, 1, id, -1, BENCH_SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, content, -1, BENCH_SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 3, ts)
        sqlite3_step(stmt)
        sqlite3_reset(stmt)
        sqlite3_clear_bindings(stmt)
    }
    sqlite3_exec(db, "COMMIT;", nil, nil, nil)
}
