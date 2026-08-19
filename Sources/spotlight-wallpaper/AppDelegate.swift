import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let scheduler = RotationScheduler()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Spotlight Wallpaper")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: InfoPopoverView(
                scheduler: scheduler,
                onPreferences: { [weak self] in self?.showPreferences() },
                onQuit: { NSApp.terminate(nil) }
            )
        )

        scheduler.start()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showPreferences() {
        popover.performClose(nil)

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
}
