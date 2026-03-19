import AppKit
import Foundation
import SwiftUI

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published var isPaused: Bool {
        didSet {
            UserDefaults.standard.set(isPaused, forKey: "historyPaused")
        }
    }

    private var timer: Timer?
    private var lastChangeCount: Int
    private weak var store: ClipboardStore?

    /// Set briefly when ClippyBar writes to clipboard, to avoid re-capture.
    var skipNextChange = false

    @AppStorage("excludedApps") var excludedAppsData: Data = Data()

    /// Cached excluded-apps set — decoded once, updated only when the
    /// underlying data changes.  Avoids JSON-decoding every poll cycle.
    private var _cachedExcludedApps: Set<String>?
    private var _cachedExcludedAppsData: Data?

    var excludedApps: Set<String> {
        get {
            if let cached = _cachedExcludedApps,
               _cachedExcludedAppsData == excludedAppsData {
                return cached
            }
            let decoded = (try? JSONDecoder().decode(Set<String>.self, from: excludedAppsData)) ?? []
            _cachedExcludedApps = decoded
            _cachedExcludedAppsData = excludedAppsData
            return decoded
        }
        set {
            excludedAppsData = (try? JSONEncoder().encode(newValue)) ?? Data()
            _cachedExcludedApps = newValue
            _cachedExcludedAppsData = excludedAppsData
        }
    }

    /// Serial queue for heavy clipboard-processing work (string ops, image I/O).
    private let processingQueue = DispatchQueue(label: "com.clipbar.clipboard-processing",
                                                 qos: .userInitiated)

    /// Debounce support — tracks whether a processing block is already scheduled.
    private var pendingWorkItem: DispatchWorkItem?

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
        isPaused = UserDefaults.standard.bool(forKey: "historyPaused")
    }

    func start(store: ClipboardStore) {
        self.store = store
        timer?.invalidate()

        let newTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkClipboard()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
    }

    func resetChangeCount() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func checkClipboard() {
        guard !isPaused else { return }

        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if skipNextChange {
            skipNextChange = false
            return
        }

        if let frontApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           excludedApps.contains(frontApp) {
            return
        }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        // Read pasteboard data on main (required by NSPasteboard) but keep it minimal.

        // --- Files: cap at 20 entries, skip files > 500 MB ---
        let maxFileCount = 20
        let maxFileSize: UInt64 = 500_000_000 // 500 MB

        let allFileURLs: [URL] = (pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL]) ?? []

        let fileURLs: [String] = Array(allFileURLs.prefix(maxFileCount)).compactMap { url in
            let path = url.path
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                  let size = attrs[.size] as? UInt64,
                  size <= maxFileSize else { return nil }
            return path
        }

        // Use contains(where:) instead of trimmingCharacters — it short-circuits on
        // the first non-whitespace char, so it's O(1) for non-empty strings vs O(n).
        let rawText = pasteboard.string(forType: .string)
        let hasNonEmptyText = rawText?.contains(where: { !$0.isWhitespace }) ?? false

        // --- Images: only check available types on main thread, defer data read ---
        let hasText = hasNonEmptyText || !fileURLs.isEmpty
        let hasImage = !hasText && (pasteboard.availableType(from: [.png, .tiff]) != nil)

        // Cancel any previously debounced work — only process the latest change.
        pendingWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }

            // File copies (e.g. from Finder)
            if !fileURLs.isEmpty {
                for path in fileURLs {
                    let item = ClipboardItem(
                        content: path,
                        contentType: .file,
                        sourceApp: sourceApp
                    )
                    Task { @MainActor [weak self] in
                        self?.store?.addItem(item)
                    }
                }
                return
            }

            if let text = rawText, hasNonEmptyText {
                // Cap captured text to avoid slow string ops and memory pressure.
                let cappedText = text.count > 50_000 ? String(text.prefix(50_000)) : text

                let contentType: ClipboardItem.ContentType =
                    ClipboardItem.looksLikeURL(cappedText) ? .link : .text

                let item = ClipboardItem(
                    content: cappedText,
                    contentType: contentType,
                    sourceApp: sourceApp
                )

                Task { @MainActor [weak self] in
                    self?.store?.addItem(item)
                }
                return
            }

            if hasImage {
                // Read image data off the main thread via a synchronous
                // main-queue dispatch — avoids blocking the UI while we
                // wait, but satisfies NSPasteboard's main-thread requirement.
                var imageData: Data?
                DispatchQueue.main.sync {
                    let pb = NSPasteboard.general
                    imageData = pb.data(forType: .png) ?? pb.data(forType: .tiff)
                }

                guard let data = imageData else { return }
                // Skip images > 5 MB raw — compress / downsample instead
                let maxRawSize = 5_000_000
                let dataToSave: Data
                if data.count > maxRawSize {
                    // Downsample to a max 1920px dimension and compress as JPEG
                    if let downsampled = Self.downsampleImageData(data, maxDimension: 1920) {
                        dataToSave = downsampled
                    } else {
                        return // unreadable image, skip
                    }
                } else {
                    dataToSave = data
                }

                let fileName = UUID().uuidString + ".png"
                self.saveImageData(dataToSave, fileName: fileName)
                let item = ClipboardItem(
                    content: fileName,
                    contentType: .image,
                    sourceApp: sourceApp
                )

                Task { @MainActor [weak self] in
                    self?.store?.addItem(item)
                }
            }
        }

        pendingWorkItem = workItem

        // Debounce: wait 100ms before processing.  If another clipboard change
        // arrives within that window the work item is cancelled above.
        processingQueue.asyncAfter(deadline: .now() + .milliseconds(100), execute: workItem)
    }

    /// Downsample large image data to fit within `maxDimension` and compress
    /// as JPEG to keep storage lightweight.  Uses ImageIO for efficient
    /// thumbnail generation without decoding the full bitmap.
    private nonisolated static func downsampleImageData(_ data: Data, maxDimension: CGFloat) -> Data? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else { return nil }

        let rep = NSBitmapImageRep(cgImage: thumbnail)
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    }

    private func saveImageData(_ data: Data, fileName: String) {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return }
        let imagesDir = appSupport.appendingPathComponent("ClippyBar/images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        let filePath = imagesDir.appendingPathComponent(fileName)
        try? data.write(to: filePath)
    }
}
