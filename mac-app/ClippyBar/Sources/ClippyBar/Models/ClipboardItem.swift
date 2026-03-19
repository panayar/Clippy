import AppKit
import Foundation

/// Represents a single clipboard history entry.
struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let content: String
    let contentType: ContentType
    let timestamp: Date
    var isPinned: Bool
    let sourceApp: String?

    enum ContentType: String, Codable {
        case text
        case image
        case link
        case file
    }

    init(
        id: String = UUID().uuidString,
        content: String,
        contentType: ContentType = .text,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceApp: String? = nil
    ) {
        self.id = id
        self.content = content
        self.contentType = contentType
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceApp = sourceApp
    }

    /// Returns a short single-line preview.  For large text, only the prefix
    /// is processed — avoids scanning the entire string for newlines.
    func preview(maxLength: Int = 80) -> String {
        switch contentType {
        case .image:
            return "Image"
        case .file:
            // content stores the full path — show just the filename
            return (content as NSString).lastPathComponent
        case .text, .link:
            break
        }

        // Only process the first (maxLength + some slack) characters
        // instead of replacing newlines in the entire (potentially huge) string.
        let limit = maxLength + 20
        let slice: Substring
        if content.count > limit {
            slice = content.prefix(limit)
        } else {
            slice = content[...]
        }

        let singleLine = slice
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")

        if singleLine.count <= maxLength { return singleLine }
        return String(singleLine.prefix(maxLength)) + "\u{2026}"
    }

    /// Shared image cache — avoids re-reading PNG files from disk on every
    /// SwiftUI body evaluation.  NSCache automatically evicts under memory pressure.
    private static let imageCache = NSCache<NSString, NSImage>()

    func loadImage() -> NSImage? {
        guard contentType == .image else { return nil }

        let key = content as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            return cached
        }

        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return nil }
        let filePath = appSupport
            .appendingPathComponent("ClippyBar/images", isDirectory: true)
            .appendingPathComponent(content)
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        guard let image = NSImage(data: data) else { return nil }

        Self.imageCache.setObject(image, forKey: key)
        return image
    }

    /// Loads the image asynchronously off the main thread, returning via
    /// the provided callback on the main queue.  Used by PickerView to
    /// avoid blocking the SwiftUI body.
    func loadImageAsync(completion: @escaping (NSImage?) -> Void) {
        guard contentType == .image else {
            completion(nil)
            return
        }

        // Fast path: already cached
        let key = content as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            completion(cached)
            return
        }

        let fileName = content
        DispatchQueue.global(qos: .userInitiated).async {
            guard let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let filePath = appSupport
                .appendingPathComponent("ClippyBar/images", isDirectory: true)
                .appendingPathComponent(fileName)
            guard let data = try? Data(contentsOf: filePath),
                  let image = NSImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            Self.imageCache.setObject(image, forKey: key)
            DispatchQueue.main.async { completion(image) }
        }
    }

    /// Returns true if the text content looks like a URL.
    static func looksLikeURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains("\n"), !trimmed.contains(" ") else { return false }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https" || scheme == "ftp"),
              url.host != nil else { return false }
        return true
    }

    // Cached formatter — creating one per call is expensive
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var relativeTimestamp: String {
        Self.relativeFormatter.localizedString(for: timestamp, relativeTo: Date())
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id && lhs.isPinned == rhs.isPinned
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isPinned)
    }
}
