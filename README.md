# spotlight-wallpaper

A tiny macOS menu bar app that brings **Windows Spotlight** to your Mac: the same
curated, rotating daily desktop images Windows shows you — including the "learn
more about this picture" info (title + photographer/copyright).

It's not a Bing Wallpaper clone or a random-Unsplash-photo app — it calls the same
public Spotlight image feed Windows itself uses, so you get the exact same photos.

<p align="center">(screenshot coming soon)</p>

## Features

- Fetches the real Windows Spotlight daily image batch (up to 4K).
- Automatically sets it as your desktop wallpaper, across every connected display.
- Rotates through the day's images on a configurable interval (every 3h / 6h / 12h / once a day).
- Menu bar popover shows the current image's **title** and **copyright/description** —
  the "learn more" equivalent — plus a one-click *Next Wallpaper*, *Refresh Now*,
  *Reveal in Finder*, and a *Learn More* button that searches the title on Bing
  (Spotlight's own "learn more" links do the same thing under the hood).
- Keeps a small local history of recently shown images with their info, not just the current one.
- No Dock icon, no window chrome — just a menu bar item.

## Install

```sh
brew tap maxgoodwin/spotlight-wallpaper
brew install spotlight-wallpaper
brew services start spotlight-wallpaper   # keeps it running across logins
```

To stop it: `brew services stop spotlight-wallpaper`.

You can also just run `spotlight-wallpaper` directly (e.g. from Terminal) without
`brew services` — it'll run until you quit it from the menu bar or close the terminal.

## Usage

Click the menu bar icon (a photo-stack glyph) to see the current wallpaper's info
and actions. Open **Preferences…** to change the rotation interval, force a
landscape/portrait image, or override the locale used to fetch images (Spotlight's
selection varies a bit by region).

CLI flags (useful for scripting/debugging):

```
spotlight-wallpaper --fetch-once   # print today's images' titles/copyright/URLs and exit
spotlight-wallpaper --version
spotlight-wallpaper --help
```

## How it works

Windows Spotlight's image feed is a plain HTTPS JSON API
(`fd.api.iris.microsoft.com/v4/api/selection`, with a `arc.msn.com/v3/...` fallback)
— it isn't actually gated to Windows, just undocumented. This app calls it directly,
downloads the images to `~/Library/Application Support/spotlight-wallpaper/`, and
uses `NSWorkspace` to set them as the desktop picture.

Endpoint and JSON field names were identified by reading the parsing logic in
[ORelio/Spotlight-Downloader](https://github.com/ORelio/Spotlight-Downloader)
(CDDL-1.0) — no code from that project is included here, just the API shape;
credit and thanks to that project for documenting it.

This project is **not affiliated with or endorsed by Microsoft**. The Spotlight API
is undocumented and may change or stop working without notice.

## Building from source

```sh
git clone https://github.com/maxgoodwin/spotlight-wallpaper
cd spotlight-wallpaper
swift build -c release
.build/release/spotlight-wallpaper
```

Requires macOS 14+ and Xcode 15+ (or the matching Command Line Tools) for Swift 5.9+.

## Contributing

Issues and PRs welcome — this is a small, single-purpose tool, so please keep
changes focused. Run `swift build` before opening a PR; CI runs the same build
plus a couple of smoke tests on macOS.

## License

[GPL-3.0-or-later](LICENSE)
