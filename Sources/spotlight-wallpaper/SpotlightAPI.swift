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

    /// Fetch today's Spotlight image batch.
    ///
    /// `preferV3` picks which feed to try first: v4 (fd.api.iris.microsoft.com, up to
    /// 4K) is what Windows 11 uses; v3 (arc.msn.com, capped at 1080p) is what Windows 10
    /// uses. These are separately-curated pools — not the same images at different
    /// resolutions — so this is a real content choice, not just a quality one. Either
    /// way, the other version is tried as a fallback if the preferred one fails.
    static func fetchImages(portrait: Bool, locale: Locale = .current, preferV3: Bool = false) async -> [SpotlightImage] {
        let region = (locale.region?.identifier ?? "US").uppercased()
        let localeTag = locale.identifier(.bcp47)

        let primary = { try await preferV3 ? fetchV3(region: region, locale: localeTag, portrait: portrait) : fetchV4(region: region, locale: localeTag, portrait: portrait) }
        let secondary = { try await preferV3 ? fetchV4(region: region, locale: localeTag, portrait: portrait) : fetchV3(region: region, locale: localeTag, portrait: portrait) }

        if let images = try? await primary(), !images.isEmpty {
            return images
        }
        if let images = try? await secondary(), !images.isEmpty {
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

    // MARK: - v3 (arc.msn.com) fallback

    private static func fetchV3(region: String, locale: String, portrait: Bool) async throws -> [SpotlightImage] {
        let isoTime = ISO8601DateFormatter().string(from: Date())
        var components = URLComponents(string: "https://arc.msn.com/v3/Delivery/Placement")!
        components.queryItems = [
            URLQueryItem(name: "pid", value: "338387"),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "ua", value: "WindowsShellClient/0"),
            URLQueryItem(name: "cdm", value: "1"),
            URLQueryItem(name: "lo", value: "80217"),
            URLQueryItem(name: "pl", value: locale),
            URLQueryItem(name: "lc", value: locale),
            URLQueryItem(name: "ctry", value: region),
            URLQueryItem(name: "time", value: isoTime),
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

            let title = (ad["title_text"] as? [String: Any])?["tx"] as? String
            let copyright = (ad["copyright_text"] as? [String: Any])?["tx"] as? String

            let imageField = portrait ? "image_fullscreen_001_portrait" : "image_fullscreen_001_landscape"
            guard
                let imageObj = ad[imageField] as? [String: Any],
                let assetString = imageObj["u"] as? String,
                let assetURL = URL(string: assetString),
                assetString.lowercased().hasPrefix("https://"),
                seen.insert(assetString).inserted
            else { continue }

            images.append(SpotlightImage(remoteURL: assetURL, title: title, copyright: copyright, fetchedAt: now))
        }

        return images
    }
}
