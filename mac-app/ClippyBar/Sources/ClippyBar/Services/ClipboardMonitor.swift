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

        // changeCount is cheap and main-actor isolated — only this read stays on main.
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if skipNextChange {
            skipNextChange = false
            return
        }

        // NSWorkspace must be accessed from main; capture before dispatching.
        let frontApp = NSWorkspace.shared.frontmostApplication
        if let bundleId = frontApp?.bundleIdentifier, excludedApps.contains(bundleId) {
            return
        }
        let sourceApp = frontApp?.localizedName

        // Cancel any previously debounced work — only process the latest change.
        pendingWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            // ALL pasteboard reads happen on the background queue. With huge
            // clipboard contents (multi-MB code dumps, large screenshots), the
            // read+copy can take hundreds of ms — running it on main froze the
            // cursor / UI on the user's machine. NSPasteboard is safe to read
            // from a single non-main thread; processingQueue is serial.
            guard let item = Self.readPasteboardItem(sourceApp: sourceApp) else { return }

            Task { @MainActor [weak self] in
                guard let store = self?.store else { return }
                switch item {
                case .single(let clipItem):
                    store.addItem(clipItem)
                case .files(let clipItems):
                    for clipItem in clipItems { store.addItem(clipItem) }
                }
            }
        }

        pendingWorkItem = workItem

        // Debounce: wait 100ms before processing.  If another clipboard change
        // arrives within that window the work item is cancelled above.
        processingQueue.asyncAfter(deadline: .now() + .milliseconds(100), execute: workItem)
    }

    /// Result of reading the current pasteboard.
    private enum ReadResult {
        case single(ClipboardItem)
        case files([ClipboardItem])
    }

    /// Reads NSPasteboard.general off the main thread. Caps the size of every
    /// content type so a single huge copy never causes a UI hitch or OOM.
    private nonisolated static func readPasteboardItem(sourceApp: String?) -> ReadResult? {
        let pb = NSPasteboard.general

        // === Files: cap at 20 entries, skip individual files > 500 MB ===
        let maxFileCount = 20
        let maxFileSize: UInt64 = 500_000_000

        if let allFileURLs = pb.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !allFileURLs.isEmpty {
            let fileItems: [ClipboardItem] = Array(allFileURLs.prefix(maxFileCount)).compactMap { url in
                let path = url.path
                guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                      let size = attrs[.size] as? UInt64,
                      size <= maxFileSize else { return nil }
                return ClipboardItem(content: path, contentType: .file, sourceApp: sourceApp)
            }
            if !fileItems.isEmpty {
                return .files(fileItems)
            }
        }

        // === Text: read raw bytes first, truncate, then decode ===
        // For multi-MB clipboards, this avoids holding the full UTF-8→String
        // conversion in memory before truncating.
        if let textData = pb.data(forType: .string) {
            let maxBytes = 200_000  // ~50K chars typical, with headroom for unicode
            let bounded = textData.count > maxBytes ? textData.prefix(maxBytes) : textData[...]
            let rawText = String(decoding: bounded, as: UTF8.self)
            if rawText.contains(where: { !$0.isWhitespace }) {
                let cappedText = rawText.count > 50_000 ? String(rawText.prefix(50_000)) : rawText
                let contentType: ClipboardItem.ContentType =
                    ClipboardItem.looksLikeURL(cappedText) ? .link : .text
                return .single(ClipboardItem(
                    content: cappedText,
                    contentType: contentType,
                    sourceApp: sourceApp
                ))
            }
        }

        // === Image ===
        guard pb.availableType(from: [.png, .tiff]) != nil,
              let data = pb.data(forType: .png) ?? pb.data(forType: .tiff) else {
            return nil
        }

        // Hard cap to avoid OOM — anything over 100 MB raw we just refuse to capture.
        guard data.count <= 100_000_000 else { return nil }

        let maxRawSize = 5_000_000
        let dataToSave: Data
        if data.count > maxRawSize {
            guard let downsampled = downsampleImageData(data, maxDimension: 1920) else { return nil }
            dataToSave = downsampled
        } else {
            dataToSave = data
        }

        let fileName = UUID().uuidString + ".png"
        saveImageData(dataToSave, fileName: fileName)
        return .single(ClipboardItem(
            content: fileName,
            contentType: .image,
            sourceApp: sourceApp
        ))
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

    private nonisolated static func saveImageData(_ data: Data, fileName: String) {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return }
        let imagesDir = appSupport.appendingPathComponent("ClippyBar/images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        let filePath = imagesDir.appendingPathComponent(fileName)
        try? data.write(to: filePath)
    }
}
