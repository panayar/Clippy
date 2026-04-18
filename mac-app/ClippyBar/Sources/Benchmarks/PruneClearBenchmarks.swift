import Benchmark
import ClippyBarCore
import Foundation

/// Measures `pruneExpiredItems` and `clearAll` at the app's real cap (500).
/// `seedDatabaseDirectly` spreads timestamps uniformly across 7 days, so
/// with `retentionDays=3` roughly 4/7 of items are past the cutoff.
let pruneClearSuite = BenchmarkSuite(name: "pruneAndClear") { suite in
    let n = 500

    suite.benchmark("pruneExpired@\(n)") { (state: inout BenchmarkState) in
        let storage = IsolatedStorage()
        defer { storage.destroy() }
        seedDatabaseDirectly(at: storage.directory, count: n)

        let store = MainActor.assumeIsolated { () -> ClipboardStore in
            let s = ClipboardStore(storageDirectory: storage.directory)
            s.configureForBenchmarking(itemLimit: max(n * 2, 1000), retentionDays: 3)
            return s
        }

        state.start()
        MainActor.assumeIsolated { store.pruneExpiredItems() }
        try state.end()

        MainActor.assumeIsolated { store.waitForPendingWrites() }
    }

    // End-to-end version: includes the background DELETE drain. The earlier
    // baseline (before the transaction wrap in `batchDeleteFromDB`) saw this
    // at ~67ms because each row fsynced independently.
    suite.benchmark("pruneExpired+drain@\(n)") { (state: inout BenchmarkState) in
        let storage = IsolatedStorage()
        defer { storage.destroy() }
        seedDatabaseDirectly(at: storage.directory, count: n)

        let store = MainActor.assumeIsolated { () -> ClipboardStore in
            let s = ClipboardStore(storageDirectory: storage.directory)
            s.configureForBenchmarking(itemLimit: max(n * 2, 1000), retentionDays: 3)
            return s
        }

        state.start()
        MainActor.assumeIsolated {
            store.pruneExpiredItems()
            store.waitForPendingWrites()
        }
        try state.end()
    }

    suite.benchmark("clearAll@\(n)") { (state: inout BenchmarkState) in
        let storage = IsolatedStorage()
        defer { storage.destroy() }
        seedDatabaseDirectly(at: storage.directory, count: n)

        let store = MainActor.assumeIsolated { () -> ClipboardStore in
            let s = ClipboardStore(storageDirectory: storage.directory)
            s.configureForBenchmarking(itemLimit: max(n * 2, 1000), retentionDays: 0)
            return s
        }

        state.start()
        MainActor.assumeIsolated { store.clearAll() }
        try state.end()

        MainActor.assumeIsolated { store.waitForPendingWrites() }
    }
}
