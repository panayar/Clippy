import Benchmark
import ClippyBarCore
import Foundation

let addItemSuite = BenchmarkSuite(name: "addItem") { suite in
    for n in [50, 200, 500] {
        // Unique-content path: new item, no match in history.
        // Measures: dedup scan + insert at head + eviction check + dispatch setup.
        suite.benchmark("unique@\(n)") { (state: inout BenchmarkState) in
            // --- setup (not timed) ---
            let storage = IsolatedStorage()
            defer { storage.destroy() }
            let store = MainActor.assumeIsolated {
                makePopulatedStore(directory: storage.directory, count: n)
            }
            let newItem = ClipboardItem(content: "fresh-\(UUID().uuidString)")

            // --- timed section ---
            state.start()
            MainActor.assumeIsolated {
                store.addItem(newItem)
            }
            try state.end()

            // --- drain background queue (not timed) ---
            MainActor.assumeIsolated { store.waitForPendingWrites() }
        }

        // Duplicate-content path: worst case for the dedup short-circuit —
        // new item's content matches the OLDEST existing entry, forcing a
        // full linear scan before the match is found.
        suite.benchmark("duplicate-tail@\(n)") { (state: inout BenchmarkState) in
            let storage = IsolatedStorage()
            defer { storage.destroy() }
            let contents = ContentProfile.generate(count: n)
            let store = MainActor.assumeIsolated { () -> ClipboardStore in
                let s = ClipboardStore(storageDirectory: storage.directory)
                s.configureForBenchmarking(itemLimit: max(n * 2, 1000), retentionDays: 0)
                for c in contents { s.addItem(ClipboardItem(content: c)) }
                s.waitForPendingWrites()
                return s
            }
            let duplicate = ClipboardItem(content: contents.first!)

            state.start()
            MainActor.assumeIsolated {
                store.addItem(duplicate)
            }
            try state.end()

            MainActor.assumeIsolated { store.waitForPendingWrites() }
        }
    }
}
