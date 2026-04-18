import Benchmark
import ClippyBarCore
import Foundation

/// Cold-launch: time from `ClipboardStore.init(storageDirectory:)` to a
/// constructed, ready store. This is the main-thread cost the menu bar
/// icon waits on before it can appear.
let loadItemsSuite = BenchmarkSuite(name: "loadItems") { suite in
    for n in [50, 200, 500] {
        suite.benchmark("coldOpen@\(n)") { (state: inout BenchmarkState) in
            let storage = IsolatedStorage()
            defer { storage.destroy() }
            seedDatabaseDirectly(at: storage.directory, count: n)

            state.start()
            let store = MainActor.assumeIsolated {
                ClipboardStore(storageDirectory: storage.directory)
            }
            try state.end()

            MainActor.assumeIsolated { store.waitForPendingWrites() }
        }
    }
}
