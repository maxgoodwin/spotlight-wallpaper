import SwiftUI

/// Non-interactive header shown at the top of the status item's menu: the
/// current wallpaper's thumbnail, title, and copyright/description. This is
/// the "learn more about this image" equivalent.
struct MenuHeaderView: View {
    @ObservedObject var scheduler: RotationScheduler

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let entry = scheduler.currentEntry {
                thumbnail(for: entry)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(entry.title ?? "Windows Spotlight")
                    .font(.headline)
                    .lineLimit(2)

                if let copyright = entry.copyright, !copyright.isEmpty {
                    Text(copyright)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } else {
                ProgressView("Fetching today's wallpaper…")
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
        .frame(width: 260)
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
}
