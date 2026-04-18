# ClippyBar Benchmark Baseline

Established before any perf/architecture work, then re-measured after the
fixes that survived review. Future benchmark runs should diff against the
**"final"** column.

## What's in scope

The app's settings UI caps **Maximum Items** at 500 and **Keep History For**
at 30 days. These benchmarks measure N = 50 / 200 / 500 — the full range
users actually see. Earlier drafts of this file included N = 5000 numbers;
those were fiction (the UI doesn't allow it) and have been removed.

## Environment

- **Machine**: Apple M3
- **OS**: macOS 15.7.2 (24G325)
- **Arch**: arm64
- **Compiler**: Swift 5.9
- **Build**: `-c release`
- **Benchmark library**: google/swift-benchmark 0.1.2
- **Iterations**: 30 per scenario, 5 warmup iterations

## How to run

```sh
cd mac-app/ClippyBar
swift build -c release --target Benchmarks
swift run -c release Benchmarks --iterations 30 --warmup-iterations 5
# filter by suite:
swift run -c release Benchmarks --filter "search"
```

## Results

### addItem — main-thread cost of one copy

| scenario                     | v0 baseline | final   | change |
|------------------------------|------------:|--------:|-------:|
| addItem.unique@50            |  122 µs     |  97 µs  | 20% faster |
| addItem.duplicate-tail@50    |  126 µs     | 100 µs  | 20% faster |
| addItem.unique@200           |  291 µs     | 252 µs  | 13% faster |
| addItem.duplicate-tail@200   |  285 µs     | 255 µs  | 11% faster |
| addItem.unique@500           |  926 µs     | 860 µs  |  7% faster |
| addItem.duplicate-tail@500   |  931 µs     | 865 µs  |  7% faster |

Wins come entirely from WAL + synchronous=NORMAL (fewer fsyncs per commit).
Absolute numbers are well under any perceptual threshold in both columns —
this is incidental hygiene, not a user-facing improvement.

### loadItems — cold-launch

| scenario                   | v0 baseline | final   | notes |
|----------------------------|------------:|--------:|-------|
| loadItems.coldOpen@50      |  141 µs | 407 µs | WAL setup overhead on fresh open |
| loadItems.coldOpen@200     |  228 µs | 635 µs | same |
| loadItems.coldOpen@500     |  494 µs | 922 µs | same |

**These got slightly slower in the benchmark.** WAL enables two sidecar
files (`-wal`, `-shm`) on first open — a cost the benchmark pays per
iteration but the real app pays once per launch. In the app, coldOpen at
N=500 is ~1 ms of disk I/O at launch; still invisible.

This number does move against us in a micro-benchmark. Keep an eye on it
if we ever want to measure real cold-launch wall-time.

### search — main-thread cost per `store.search()` call

| scenario                |    time |  ± std | notes |
|-------------------------|--------:|-------:|-------|
| search.noMatch@50       | 8.36 ms |  6.5%  | full scan, no early-out |
| search.selective@50     | 8.32 ms |  1.4%  | 1 match of 50 |
| search.broad@50         |   13 µs |  6.8%  | early-out per item |
| search.noMatch@200      | 22.2 ms |  2.1%  | |
| search.selective@200    | 22.0 ms |  1.0%  | |
| search.broad@200        |   44 µs |  4.5%  | |
| search.noMatch@500      | 78.5 ms |  0.6%  | |
| search.selective@500    | 79.0 ms |  0.9%  | |
| search.broad@500        |  112 µs |  5.8%  | |

**`store.search()` itself is unchanged** — still an O(n · content-length)
linear scan. What changed: `PickerView` now debounces the text-field to
wait 150 ms after the last keystroke before calling it, so a 6-character
query goes from ~6 × 79 ms ≈ 475 ms of main-thread stalls down to one
~79 ms call after the user stops typing.

That's the **only user-facing UX improvement this branch shipped**. It's
in the view layer, not the store, so it doesn't show up in these numbers.

### prune + clearAll — batch write paths

| scenario                                | v0 baseline | final   | change |
|-----------------------------------------|------------:|--------:|-------:|
| pruneExpired@500 (main-thread only)     |   9.5 µs    |  7.8 µs | ~equal |
| **pruneExpired+drain@500** (incl. disk) | **67.3 ms** | **1.1 ms** | **62× faster** |
| clearAll@500                            |   58 µs     |  38 µs  | ~equal |

`pruneExpiredItems` used to dispatch N individual DELETE statements to the
background queue, each in its own implicit transaction + fsync. At 500
expired rows on an aggressive retention setting, that was ~67 ms of disk
saturation at launch. The `batchDeleteFromDB` helper wraps BEGIN/COMMIT
around the whole batch with one prepared statement — **one fsync instead
of ~500**.

User-visible impact: none (it's background I/O). Correctness impact: real.
If the user lowers "Keep History For" from 30 days to 1 day, the next launch
will prune a big backlog — this change keeps it quiet.

## What shipped

The perf work settled on four small, low-risk changes:

1. **Search debounce (150 ms)** in `PickerView.swift`. The only user-facing
   UX improvement. Typing no longer stalls the main thread on every
   keystroke. Clear button and Return flush the debounce immediately.
2. **`PRAGMA journal_mode = WAL` + `synchronous = NORMAL`** on DB open.
   Three lines. Free hygiene. Small `addItem` win, small `loadItems`
   regression, wash overall.
3. **Transaction wrap in `pruneExpiredItems`** (`batchDeleteFromDB` helper).
   Collapses the fsync storm on backlog-heavy prunes.
4. **Library split + benchmark harness.** Not a perf change — a structural
   one. `ClippyBar` executable now depends on a `ClippyBarCore` library,
   which both the app shim and the benchmarks import. Gets the codebase
   into a shape where unit tests + CI regressions are cheap to add later.

## What was tried and reverted

Earlier iterations of this branch also shipped:

- **Background `loadItems`** (async init with `isLoaded` state, `awaitLoad`,
  run-loop pumping). Saved ~5 ms of main-thread time at N=5000, which
  cannot happen. At N=500 the savings were ~100 µs, invisible. The async
  complexity (dedup-merge race, polling-vs-continuation tradeoffs) wasn't
  paying for itself.
- **Prepared-statement cache** (`StatementCache` class, per-call plumbing,
  deinit-ordering fix). ~40 µs saved at N=200, invisible. Added real
  complexity (new reference type, new lifecycle, key-path API).
- **In-memory dedup index + non-pinned counter** (`dedupIndex`,
  `nonPinnedCount`, invariant maintenance across 6+ mutation sites). 22×
  faster `addItem` at N=500 sounded great but both sides of that
  comparison were sub-millisecond. Replaced a 25-line scan with a ~150-
  line invariant, for no perceivable benefit.

Each of these optimized a non-problem at the app's realistic caps. The
benchmarks at N=5000 were measuring a world that doesn't exist in the
shipped product.

## What's still open

- **SQLite actor refactor.** Drop `SendableDBPointer` and `@unchecked
  Sendable` tricks. No perf win — correctness and testability. Worth doing
  if/when a test target lands.
- **FTS5 for search.** Would take the 79 ms-at-N=500 scan down to
  microseconds. Only matters if "unlimited history" ever ships, which the
  current product doesn't.
- **View-layer refactors:** `PickerView.swift` is 815 lines, key-event
  routing uses `NotificationCenter` as an untyped bus. Neither affects
  perf; both make future feature work harder.

## What's intentionally *not* measured here

- Pasteboard poll steady-state cost. Sampling territory (`powermetrics`),
  not SPM micro-benchmarks.
- Hotkey registration, auto-paste delay, SwiftUI render time.
- Memory footprint.
- Image downsampling (`ClipboardMonitor.downsampleImageData`).
- UI-level search latency. The debounce is the whole-pipeline change; a
  SwiftUI test with simulated typing would be the right way to measure it.
