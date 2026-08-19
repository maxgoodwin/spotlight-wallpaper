import AppKit

/// Applies a local image file as the desktop picture across every connected screen.
enum WallpaperManager {
    @discardableResult
    static func setWallpaper(_ imageURL: URL) -> Bool {
        var succeededOnAtLeastOneScreen = false
        for screen in NSScreen.screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: [:])
                succeededOnAtLeastOneScreen = true
            } catch {
                FileHandle.standardError.write("spotlight-wallpaper: failed to set wallpaper on \(screen): \(error)\n".data(using: .utf8)!)
            }
        }
        return succeededOnAtLeastOneScreen
    }
}
