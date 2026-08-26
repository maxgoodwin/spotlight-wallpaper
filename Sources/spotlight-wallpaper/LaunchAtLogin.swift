import Foundation
import ServiceManagement

/// "Launch at login" toggle, backed by `SMAppService.mainApp`.
///
/// `SMAppService.mainApp` only works for code running from a proper `.app` bundle
/// (see README — the app is distributed as a Homebrew cask, not a bare binary), so
/// outside that context this degrades gracefully rather than pretending to succeed.
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
