import AppKit

/// Non-interactive header row for the status item's menu: the current
/// wallpaper's thumbnail, title, and copyright/description. This is the
/// "learn more about this image" equivalent.
///
/// Built with plain AppKit views rather than SwiftUI/NSHostingView: SwiftUI
/// `Image` content hosted inside a custom `NSMenuItem` view does not reliably
/// composite through NSMenu's rendering pipeline (text-only SwiftUI content
/// renders fine, which is what made this easy to miss). NSImageView has no
/// such issue and is the standard approach for custom menu item content.
final class MenuHeaderView: NSView {
    private let imageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let copyrightLabel = NSTextField(labelWithString: "")

    private static let width: CGFloat = 260
    private static let horizontalPadding: CGFloat = 14
    private static let imageHeight: CGFloat = 120
    private static let titleHeight: CGFloat = 32
    private static let copyrightHeight: CGFloat = 28
    private static let totalHeight: CGFloat =
        8 + imageHeight + 6 + titleHeight + 2 + copyrightHeight + 8

    override var isFlipped: Bool { true }

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: Self.width, height: Self.totalHeight))

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 6
        imageView.layer?.masksToBounds = true

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.cell?.wraps = true

        copyrightLabel.font = .systemFont(ofSize: 11)
        copyrightLabel.textColor = .secondaryLabelColor
        copyrightLabel.lineBreakMode = .byWordWrapping
        copyrightLabel.cell?.wraps = true

        let contentWidth = Self.width - 2 * Self.horizontalPadding
        var y: CGFloat = 8
        imageView.frame = NSRect(x: Self.horizontalPadding, y: y, width: contentWidth, height: Self.imageHeight)
        y += Self.imageHeight + 6
        titleLabel.frame = NSRect(x: Self.horizontalPadding, y: y, width: contentWidth, height: Self.titleHeight)
        y += Self.titleHeight + 2
        copyrightLabel.frame = NSRect(x: Self.horizontalPadding, y: y, width: contentWidth, height: Self.copyrightHeight)

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(copyrightLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(image: NSImage?, title: String, copyright: String?) {
        imageView.image = image
        titleLabel.stringValue = title
        copyrightLabel.stringValue = copyright ?? ""
        copyrightLabel.isHidden = (copyright ?? "").isEmpty
    }
}
