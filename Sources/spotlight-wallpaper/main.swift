import AppKit

let version = "0.1.9"

func printUsage() {
    print("""
    spotlight-wallpaper \(version)
    Rotates your macOS desktop wallpaper through the real Windows Spotlight daily images.

    Usage:
      spotlight-wallpaper                Run as a menu bar app (default)
      spotlight-wallpaper --fetch-once    Fetch today's Spotlight images and print their
                                          titles/copyright/URLs, without changing anything
      spotlight-wallpaper --version       Print the version and exit
      spotlight-wallpaper --help          Show this message
    """)
}

let arguments = CommandLine.arguments.dropFirst()

if arguments.contains("--version") {
    print(version)
    exit(0)
}

if arguments.contains("--help") || arguments.contains("-h") {
    printUsage()
    exit(0)
}

if arguments.contains("--fetch-once") {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        let images = await SpotlightAPI.fetchImages(portrait: false, locale: Preferences.effectiveLocale)
        if images.isEmpty {
            print("No images returned.")
        } else {
            for image in images {
                print("- \(image.title ?? "(no title)")")
                if let copyright = image.copyright { print("  \(copyright)") }
                print("  \(image.remoteURL.absoluteString)")
            }
        }
        semaphore.signal()
    }
    semaphore.wait()
    exit(0)
}

// main.swift's top-level code runs on the main thread but isn't inferred as
// @MainActor by the compiler; assertIsolated is safe here since process startup
// on macOS is guaranteed to happen on the main thread.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
