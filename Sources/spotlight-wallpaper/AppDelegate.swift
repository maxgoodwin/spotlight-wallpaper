import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let scheduler = RotationScheduler()
    private var statusItem: NSStatusItem!
    private var preferencesWindow: NSWindow?
    private var revealInFinderItem: NSMenuItem?
    private var learnMoreItem: NSMenuItem?
    private let headerView = MenuHeaderView()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Spotlight Wallpaper")
        statusItem.menu = buildMenu()

        scheduler.onUpdate = { [weak self] in self?.refreshHeader() }
        scheduler.start()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        let headerItem = NSMenuItem()
        headerItem.view = headerView
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
        refreshHeader()
        let entry = scheduler.currentEntry
        revealInFinderItem?.isEnabled = entry != nil
        learnMoreItem?.isEnabled = !(entry?.title ?? "").isEmpty
    }

    private func refreshHeader() {
        guard let entry = scheduler.currentEntry else {
            headerView.configure(image: nil, title: "Fetching today's wallpaper…", copyright: nil)
            return
        }
        let image = NSImage(contentsOf: scheduler.localURL(for: entry))
        headerView.configure(image: image, title: entry.title ?? "Windows Spotlight", copyright: entry.copyright)
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
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 260),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            let hostingController = NSHostingController(rootView: PreferencesView(scheduler: scheduler))
            // Without this, the window doesn't auto-size to the SwiftUI content's ideal
            // size — it just keeps whatever frame it was created with, clipping content
            // like wrapped multi-line text. .resizable in styleMask above is a manual
            // fallback in case content ever grows beyond what preferredContentSize catches.
            hostingController.sizingOptions = [.preferredContentSize]
            window.title = "Spotlight Wallpaper Preferences"
            window.contentViewController = hostingController
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
