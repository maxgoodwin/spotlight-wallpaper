import Foundation

/// User-configurable settings, backed by UserDefaults so they survive relaunches
/// (including relaunches driven by `brew services`).
enum Preferences {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let rotationIntervalHours = "rotationIntervalHours"
        static let localeOverride = "localeOverride"
        static let orientation = "orientation"
    }

    enum Orientation: String, CaseIterable {
        case auto, landscape, portrait
    }

    /// How often to advance to the next cached image. Defaults to once a day, matching
    /// Windows Spotlight's default cadence.
    static var rotationIntervalHours: Double {
        get {
            let stored = defaults.double(forKey: Key.rotationIntervalHours)
            return stored > 0 ? stored : 24
        }
        set { defaults.set(newValue, forKey: Key.rotationIntervalHours) }
    }

    /// BCP-47 locale tag, e.g. "en-US". Nil means auto-detect from the system locale.
    static var localeOverride: String? {
        get { defaults.string(forKey: Key.localeOverride) }
        set { defaults.set(newValue, forKey: Key.localeOverride) }
    }

    static var orientation: Orientation {
        get { Orientation(rawValue: defaults.string(forKey: Key.orientation) ?? "") ?? .auto }
        set { defaults.set(newValue.rawValue, forKey: Key.orientation) }
    }

    static var effectiveLocale: Locale {
        if let tag = localeOverride, !tag.isEmpty {
            return Locale(identifier: tag)
        }
        return .current
    }
}
