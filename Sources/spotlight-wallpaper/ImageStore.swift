import Foundation

/// Downloads Spotlight images to disk and keeps a JSON index of their metadata
/// (title/copyright/fetch date) so the info popover can show details for any
/// cached image, not just the one currently set as wallpaper.
final class ImageStore {
    struct Entry: Codable {
        let fileName: String
        let remoteURL: URL
        let title: String?
        let copyright: String?
        let fetchedAt: Date
    }

    static let maxCachedImages = 30

    private let imagesDirectory: URL
    private let indexFile: URL
    private let fileManager = FileManager.default

    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let root = appSupport.appendingPathComponent("spotlight-wallpaper", isDirectory: true)
        imagesDirectory = root.appendingPathComponent("images", isDirectory: true)
        indexFile = root.appendingPathComponent("index.json")
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    func localURL(for entry: Entry) -> URL {
        imagesDirectory.appendingPathComponent(entry.fileName)
    }

    /// Downloads any images not already cached, updates the index, and prunes old entries.
    /// Returns the full, updated list of cached entries (newest last).
    @discardableResult
    func store(_ images: [SpotlightImage]) async -> [Entry] {
        var index = loadIndex()
        let existingFileNames = Set(index.map(\.fileName))

        for image in images where !existingFileNames.contains(image.fileName) {
            let destination = imagesDirectory.appendingPathComponent(image.fileName)
            do {
                let (tempURL, response) = try await URLSession.shared.download(from: image.remoteURL)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    try? fileManager.removeItem(at: tempURL)
                    continue
                }
                if fileManager.fileExists(atPath: destination.path) {
                    try? fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: tempURL, to: destination)
                index.append(Entry(
                    fileName: image.fileName,
                    remoteURL: image.remoteURL,
                    title: image.title,
                    copyright: image.copyright,
                    fetchedAt: image.fetchedAt
                ))
            } catch {
                FileHandle.standardError.write("spotlight-wallpaper: failed to download \(image.remoteURL): \(error)\n".data(using: .utf8)!)
            }
        }

        index.sort { $0.fetchedAt < $1.fetchedAt }
        prune(&index)
        saveIndex(index)
        return index
    }

    func loadIndex() -> [Entry] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            let data = try? Data(contentsOf: indexFile),
            let entries = try? decoder.decode([Entry].self, from: data)
        else { return [] }
        return entries
    }

    private func saveIndex(_ entries: [Entry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: indexFile, options: .atomic)
    }

    private func prune(_ entries: inout [Entry]) {
        guard entries.count > Self.maxCachedImages else { return }
        let overflow = entries.count - Self.maxCachedImages
        let toRemove = entries.prefix(overflow)
        for entry in toRemove {
            try? fileManager.removeItem(at: localURL(for: entry))
        }
        entries.removeFirst(overflow)
    }
}

extension ImageStore.Entry: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.fileName == rhs.fileName }
}
