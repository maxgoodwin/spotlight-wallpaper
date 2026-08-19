// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "spotlight-wallpaper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "spotlight-wallpaper",
            path: "Sources/spotlight-wallpaper"
        )
    ]
)
