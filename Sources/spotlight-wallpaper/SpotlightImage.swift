import Foundation

/// A single Windows Spotlight image, as returned by Microsoft's Spotlight feed.
struct SpotlightImage: Codable, Identifiable, Hashable {
    var id: String { remoteURL.absoluteString }

    let remoteURL: URL
    let title: String?
    let copyright: String?
    let fetchedAt: Date

    /// Filename used both remotely (last path component) and for the local cache copy.
    var fileName: String {
        let base = remoteURL.lastPathComponent.components(separatedBy: "?").first ?? remoteURL.lastPathComponent
        if base.isEmpty || !base.contains(".") {
            return "\(remoteURL.absoluteString.stableHash).jpg"
        }
        return base
    }
}

private extension String {
    /// Deterministic short hash used when the remote URL has no usable filename.
    var stableHash: String {
        var hasher = Hasher()
        hasher.combine(self)
        return String(format: "%08x", UInt32(bitPattern: Int32(truncatingIfNeeded: hasher.finalize())))
    }
}
