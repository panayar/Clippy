import Benchmark
import ClippyBarCore
import Foundation

/// Measures `ClipboardStore.search(query:typeFilters:)` across three query
/// shapes at three history sizes. Search is a linear scan with
/// `String.range(of:options:.caseInsensitive)` per item; today it's saved
/// only by the item-count cap. FTS5 would change this.
let searchSuite = BenchmarkSuite(name: "search") { suite in
    for n in [50, 200, 500] {
        // Pre-populate once per scenario outside the timed section.
        // Use `@MainActor` capture via assumeIsolated inside the closure.

        // Worst case: query doesn't match anything — full scan, no early-out.
        suite.benchmark("noMatch@\(n)") { (state: inout BenchmarkState) in
            let storage = IsolatedStorage()
            defer { storage.destroy() }
            seedDatabaseDirectly(at: storage.directory, count: n)
            let store = MainActor.assumeIsolated {
                ClipboardStore(storageDirectory: storage.directory)
            }

            state.start()
            let result = MainActor.assumeIsolated {
                store.search(query: "zzznotfoundxyz")
            }
            try state.end()
            _ = result.count
        }

        // Selective: exactly one match out of N. Realistic for specific
        // snippet lookup.
        suite.benchmark("selective@\(n)") { (state: inout BenchmarkState) in
            let storage = IsolatedStorage()
            defer { storage.destroy() }
            seedDatabaseDirectly(at: storage.directory, count: n)
            let store = MainActor.assumeIsolated {
                ClipboardStore(storageDirectory: storage.directory)
            }
            // "item-42-" prefix matches exactly the content with index 42.
            let needle = "item-\(n / 2)-"

            state.start()
            let result = MainActor.assumeIsolated {
                store.search(query: needle)
            }
            try state.end()
            _ = result.count
        }

        // Broad: query matches every item (worst case for the filtered copy).
        suite.benchmark("broad@\(n)") { (state: inout BenchmarkState) in
            let storage = IsolatedStorage()
            defer { storage.destroy() }
            seedDatabaseDirectly(at: storage.directory, count: n)
            let store = MainActor.assumeIsolated {
                ClipboardStore(storageDirectory: storage.directory)
            }

            state.start()
            let result = MainActor.assumeIsolated {
                store.search(query: "item-")
            }
            try state.end()
            _ = result.count
        }
    }
}
