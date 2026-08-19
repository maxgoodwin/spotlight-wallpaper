import AppKit

/// Drives the whole rotation lifecycle: fetch today's Spotlight batch if we don't
/// have one yet, apply an image as wallpaper, and advance through the cached batch
/// on a timer. A new calendar day naturally triggers a fresh fetch, since "today's
/// entries" becomes empty once midnight passes.
@MainActor
final class RotationScheduler: ObservableObject {
    private let store = ImageStore()
    private var timer: Timer?

    @Published private(set) var currentEntry: ImageStore.Entry?
    var onUpdate: (() -> Void)?

    func localURL(for entry: ImageStore.Entry) -> URL {
        store.localURL(for: entry)
    }

    private static let currentFileNameKey = "currentFileName"

    func start() {
        Task { await bootstrap() }
        rescheduleTimer()
    }

    /// Call after the user changes the rotation interval in Preferences.
    func rescheduleTimer() {
        timer?.invalidate()
        let interval = max(Preferences.rotationIntervalHours, 0.25) * 3600
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tick() }
        }
    }

    /// User-triggered "Next wallpaper".
    func advanceManually() {
        Task { await tick(forceAdvance: true) }
    }

    /// User-triggered "Refresh now" — always hits the network for a new batch.
    func refreshManually() {
        Task { await refresh() }
    }

    private func bootstrap() async {
        let index = store.loadIndex()
        let today = todaysEntries(from: index)

        if today.isEmpty {
            await refresh()
            return
        }

        let savedFileName = UserDefaults.standard.string(forKey: Self.currentFileNameKey)
        let entry = today.first(where: { $0.fileName == savedFileName }) ?? today[0]
        apply(entry)
    }

    private func tick(forceAdvance: Bool = false) async {
        let index = store.loadIndex()
        let today = todaysEntries(from: index)

        guard !today.isEmpty else {
            await refresh()
            return
        }

        if let current = currentEntry, let currentIndex = today.firstIndex(of: current) {
            let next = today[(currentIndex + 1) % today.count]
            apply(next)
        } else {
            apply(today[0])
        }

        if forceAdvance == false, today.count == 1 {
            // Only one image cached for today (e.g. the API returned a single item) —
            // refresh in the background so the next tick has more to rotate through.
            await refresh()
        }
    }

    private func refresh() async {
        let portrait = isPortraitMainScreen()
        let images = await SpotlightAPI.fetchImages(portrait: portrait, locale: Preferences.effectiveLocale, preferV3: Preferences.matchWindows10)
        guard !images.isEmpty else {
            FileHandle.standardError.write("spotlight-wallpaper: fetch returned no images, keeping current wallpaper\n".data(using: .utf8)!)
            return
        }
        let index = await store.store(images)
        // Apply one of the images from *this* fetch, not just-any entry from today —
        // store() sorts the index by fetch time, so on a second fetch within the same
        // day (manual refresh, or switching the Windows 10/11 feed), "today's entries"
        // also contains earlier-today images and picking the first of those would just
        // silently re-apply the old one instead of showing what was just fetched.
        let fetchedFileNames = Set(images.map(\.fileName))
        let newlyStored = index.filter { fetchedFileNames.contains($0.fileName) }
        if let first = newlyStored.first {
            apply(first)
        }
    }

    private func apply(_ entry: ImageStore.Entry) {
        currentEntry = entry
        UserDefaults.standard.set(entry.fileName, forKey: Self.currentFileNameKey)
        WallpaperManager.setWallpaper(store.localURL(for: entry))
        onUpdate?()
    }

    private func todaysEntries(from index: [ImageStore.Entry]) -> [ImageStore.Entry] {
        index.filter { Calendar.current.isDateInToday($0.fetchedAt) }
    }

    private func isPortraitMainScreen() -> Bool {
        switch Preferences.orientation {
        case .landscape: return false
        case .portrait: return true
        case .auto:
            guard let frame = NSScreen.main?.frame else { return false }
            return frame.height > frame.width
        }
    }
}
