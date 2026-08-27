import Foundation

/// Fetches images from Microsoft's Spotlight feed.
///
/// This is the same public HTTPS JSON API that Windows itself calls to populate
/// Spotlight lock screen / desktop wallpapers — it is not Windows-specific, just
/// undocumented. Endpoint and field names verified against the parsing logic in
/// ORelio/Spotlight-Downloader (CDDL-1.0); reimplemented here from scratch in Swift.
enum SpotlightAPI {
    enum APIError: Error, LocalizedError {
        case badResponse
        case noImages

        var errorDescription: String? {
            switch self {
            case .badResponse: return "Spotlight API returned an unexpected response."
            case .noImages: return "Spotlight API returned no usable images."
            }
        }
    }

    /// Fetch today's Spotlight image batch from the v4 feed (fd.api.iris.microsoft.com,
    /// up to 4K) — the same one Windows 11 uses.
    static func fetchImages(portrait: Bool, locale: Locale = .current) async -> [SpotlightImage] {
        let region = (locale.region?.identifier ?? "US").uppercased()
        let localeTag = locale.identifier(.bcp47)

        if let images = try? await fetchV4(region: region, locale: localeTag, portrait: portrait), !images.isEmpty {
            return images
        }
        return []
    }

    // MARK: - v4 (fd.api.iris.microsoft.com)

    private static func fetchV4(region: String, locale: String, portrait: Bool) async throws -> [SpotlightImage] {
        var components = URLComponents(string: "https://fd.api.iris.microsoft.com/v4/api/selection")!
        components.queryItems = [
            URLQueryItem(name: "placement", value: "88000820"),
            URLQueryItem(name: "bcnt", value: "4"),
            URLQueryItem(name: "country", value: region),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "fmt", value: "json"),
        ]
        guard let url = components.url else { throw APIError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.badResponse
        }

        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let batchrsp = root["batchrsp"] as? [String: Any],
            let items = batchrsp["items"] as? [[String: Any]]
        else {
            throw APIError.badResponse
        }

        let now = Date()
        var seen = Set<String>()
        var images: [SpotlightImage] = []

        for wrapper in items {
            guard
                let itemString = wrapper["item"] as? String,
                let itemData = itemString.data(using: .utf8),
                let item = try? JSONSerialization.jsonObject(with: itemData) as? [String: Any],
                let ad = item["ad"] as? [String: Any]
            else { continue }

            var title = (ad["iconHoverText"] as? String)?
                .components(separatedBy: .newlines).first
            if title == nil || title?.isEmpty == true {
                title = ad["title"] as? String
            }
            let copyright = ad["copyright"] as? String

            let imageField = portrait ? "portraitImage" : "landscapeImage"
            guard
                let imageObj = ad[imageField] as? [String: Any],
                let assetString = imageObj["asset"] as? String,
                let assetURL = URL(string: assetString),
                assetString.lowercased().hasPrefix("https://"),
                seen.insert(assetString).inserted
            else { continue }

            images.append(SpotlightImage(remoteURL: assetURL, title: title, copyright: copyright, fetchedAt: now))
        }

        return images
    }
}
