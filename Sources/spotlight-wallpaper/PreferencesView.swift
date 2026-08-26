import SwiftUI

struct PreferencesView: View {
    var scheduler: RotationScheduler

    @State private var rotationIntervalHours: Double = Preferences.rotationIntervalHours
    @State private var orientation: Preferences.Orientation = Preferences.orientation
    @State private var localeOverride: String = Preferences.localeOverride ?? ""
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @State private var matchWindows10: Bool = Preferences.matchWindows10

    private static let intervalOptions: [(label: String, hours: Double)] = [
        ("Every 3 hours", 3),
        ("Every 6 hours", 6),
        ("Every 12 hours", 12),
        ("Once a day", 24),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            row("Change wallpaper") {
                Picker("", selection: $rotationIntervalHours) {
                    ForEach(Self.intervalOptions, id: \.hours) { option in
                        Text(option.label).tag(option.hours)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .onChange(of: rotationIntervalHours) { _, newValue in
                    Preferences.rotationIntervalHours = newValue
                    scheduler.rescheduleTimer()
                }
            }

            row("Image orientation") {
                Picker("", selection: $orientation) {
                    Text("Auto (match main display)").tag(Preferences.Orientation.auto)
                    Text("Landscape").tag(Preferences.Orientation.landscape)
                    Text("Portrait").tag(Preferences.Orientation.portrait)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .onChange(of: orientation) { _, newValue in
                    Preferences.orientation = newValue
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Locale override")
                    .font(.subheadline)
                TextField("e.g. en-US — leave blank to auto-detect", text: $localeOverride)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: localeOverride) { _, newValue in
                        Preferences.localeOverride = newValue.isEmpty ? nil : newValue
                    }
                Text("Currently using: \(effectiveLocaleDisplay)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Match Windows 10 wallpapers", isOn: $matchWindows10)
                    .onChange(of: matchWindows10) { _, newValue in
                        Preferences.matchWindows10 = newValue
                        scheduler.refreshManually()
                    }
                Text("Windows 10 and 11 pull from separately-curated image pools, not the same photos at different resolutions. On: matches Windows 10, capped at 1080p. Off (default): the sharper 4K pool Windows 11 uses.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if LaunchAtLogin.isSupported {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if !LaunchAtLogin.setEnabled(newValue) {
                            launchAtLogin = LaunchAtLogin.isEnabled
                        }
                    }
            } else {
                Text("Launch at login is only available when running the Spotlight Wallpaper app bundle, not the bare command-line binary.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(width: 380, alignment: .leading)
        .fixedSize()
    }

    @ViewBuilder
    private func row(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label)
            Spacer(minLength: 16)
            content()
                .fixedSize()
        }
    }

    private var effectiveLocaleDisplay: String {
        let tag = Preferences.effectiveLocale.identifier(.bcp47)
        return localeOverride.isEmpty ? "\(tag) (auto-detected)" : tag
    }
}
