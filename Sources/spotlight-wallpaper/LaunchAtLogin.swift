import Foundation
import ServiceManagement

/// Best-effort "launch at login" toggle for people running the binary directly
/// (double-clicking it or invoking it from Terminal on their own).
///
/// The primary, recommended way to keep spotlight-wallpaper running across logins
/// is `brew services start spotlight-wallpaper`, which registers a proper launchd
/// LaunchAgent — see README. `SMAppService.mainApp` is really designed for apps
/// running from an `.app` bundle, so outside that context this degrades gracefully
/// rather than pretending to succeed.
enum LaunchAtLogin {
    static var isSupported: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    static var isEnabled: Bool {
        guard isSupported else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard isSupported else { return false }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            FileHandle.standardError.write("spotlight-wallpaper: launch-at-login toggle failed: \(error)\n".data(using: .utf8)!)
            return false
        }
    }
}
