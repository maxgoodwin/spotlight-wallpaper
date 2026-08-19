import SwiftUI
import AppKit

/// The "learn more about this image" replacement: shows the current wallpaper's
/// thumbnail, title, and copyright/description, plus quick actions.
struct InfoPopoverView: View {
    @ObservedObject var scheduler: RotationScheduler
    var onPreferences: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let entry = scheduler.currentEntry {
                thumbnail(for: entry)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(entry.title ?? "Windows Spotlight")
                    .font(.headline)
                    .lineLimit(2)

                if let copyright = entry.copyright, !copyright.isEmpty {
                    Text(copyright)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            } else {
                ProgressView("Fetching today's wallpaper…")
                    .frame(maxWidth: .infinity, minHeight: 140)
            }

            Divider()

            Button("Next Wallpaper") { scheduler.advanceManually() }
            Button("Refresh Now") { scheduler.refreshManually() }
            if let entry = scheduler.currentEntry {
                Button("Reveal in Finder") { revealInFinder(entry) }
                Button("Learn More…") { learnMore(entry) }
                    .disabled((entry.title ?? "").isEmpty)
            }

            Divider()

            Button("Preferences…", action: onPreferences)
            Button("Quit spotlight-wallpaper", action: onQuit)
        }
        .buttonStyle(.plain)
        .padding(14)
        .frame(width: 280)
    }

    @ViewBuilder
    private func thumbnail(for entry: ImageStore.Entry) -> some View {
        if let image = NSImage(contentsOf: scheduler.localURL(for: entry)) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle().fill(.quaternary)
        }
    }

    private func revealInFinder(_ entry: ImageStore.Entry) {
        NSWorkspace.shared.activateFileViewerSelecting([scheduler.localURL(for: entry)])
    }

    private func learnMore(_ entry: ImageStore.Entry) {
        guard let title = entry.title, !title.isEmpty,
              let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.bing.com/search?q=\(query)")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
