import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let scheduler = RotationScheduler()
    private var statusItem: NSStatusItem!
    private var preferencesWindow: NSWindow?
    private var revealInFinderItem: NSMenuItem?
    private var learnMoreItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Spotlight Wallpaper")
        statusItem.menu = buildMenu()

        scheduler.start()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        // Left enabled deliberately: a disabled NSMenuItem with a custom NSHostingView
        // suppresses layer-backed bitmap content (SwiftUI Image) even though text still
        // renders fine via a different path. Clicking the header just closes the menu,
        // same as clicking any other row with no side effect — harmless.
        let headerItem = NSMenuItem()
        headerItem.view = NSHostingView(rootView: MenuHeaderView(scheduler: scheduler))
        menu.addItem(headerItem)

        menu.addItem(.separator())
        menu.addItem(item("Next Wallpaper", #selector(nextWallpaper)))
        menu.addItem(item("Refresh Now", #selector(refreshNow)))

        let reveal = item("Reveal in Finder", #selector(revealInFinder))
        menu.addItem(reveal)
        revealInFinderItem = reveal

        let learnMore = item("Learn More…", #selector(learnMore))
        menu.addItem(learnMore)
        learnMoreItem = learnMore

        menu.addItem(.separator())
        menu.addItem(item("Preferences…", #selector(openPreferences)))
        menu.addItem(.separator())
        menu.addItem(item("Quit Spotlight Wallpaper", #selector(quit), keyEquivalent: "q"))

        return menu
    }

    private func item(_ title: String, _ action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        let entry = scheduler.currentEntry
        revealInFinderItem?.isEnabled = entry != nil
        learnMoreItem?.isEnabled = !(entry?.title ?? "").isEmpty
    }

    // MARK: - Actions

    @objc private func nextWallpaper() {
        scheduler.advanceManually()
    }

    @objc private func refreshNow() {
        scheduler.refreshManually()
    }

    @objc private func revealInFinder() {
        guard let entry = scheduler.currentEntry else { return }
        NSWorkspace.shared.activateFileViewerSelecting([scheduler.localURL(for: entry)])
    }

    @objc private func learnMore() {
        guard
            let entry = scheduler.currentEntry,
            let title = entry.title, !title.isEmpty,
            let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://www.bing.com/search?q=\(query)")
        else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Spotlight Wallpaper Preferences"
            window.contentViewController = NSHostingController(rootView: PreferencesView(scheduler: scheduler))
            window.isReleasedWhenClosed = false
            window.center()
            preferencesWindow = window
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
