import AppKit
import SwiftUI
import IOKit.ps
import QuartzCore

@main
struct AERISApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 224, height: 34),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
panel.contentView = NSHostingView(rootView: IslandView { [weak panel] expanded in
    guard let panel else { return }

    let newWidth: CGFloat = expanded ? 340 : 224
    let newHeight: CGFloat = expanded ? 190 : 34

    let topEdge = panel.frame.maxY
    let screenFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
    let originX = screenFrame.midX - newWidth / 2

NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.38
    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    panel.animator().setFrame(
        NSRect(
            x: originX,
            y: topEdge - newHeight,
            width: newWidth,
            height: newHeight
        ),
        display: true
    )
}
        })

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .normal
        panel.collectionBehavior = []
        // Keep AERIS out of other apps' fullscreen Spaces and let normal app windows cover it.
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = false

        if let screen = NSScreen.main {
            panel.setFrameOrigin(NSPoint(x: screen.frame.midX - 112, y: screen.frame.maxY - 49))
        }
        panel.orderFront(nil)
        self.panel = panel
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

struct IslandView: View {
    let onExpansionChanged: (Bool) -> Void

    @State private var now = Date()
    @State private var expanded = false
    @State private var battery = BatteryInfo.read()
    @State private var hovering = false
    @State private var music = MusicInfo.read()
    @State private var seekPosition: Double = 0
    @State private var isSeeking = false
    @State private var activeApp = ActiveAppInfo.read()
    @State private var weather = WeatherInfo.loading

private let weatherRefresh = Timer.publish(
    every: 900,
    on: .main,
    in: .common
).autoconnect()

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let refresh = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    private let musicRefresh = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    private let activeAppRefresh = Timer.publish(
        every: 2,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(now, format: .dateTime.hour().minute())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.96))
                    .frame(minWidth: 37, alignment: .leading)

                Spacer(minLength: 0)

                if !expanded {
                    HStack(spacing: 4) {
                        Image(
                            nsImage: NSWorkspace.shared.icon(
                                forFile: NSWorkspace.shared.urlForApplication(
                                    withBundleIdentifier: activeApp.bundleID
                                )?.path ?? "/System/Applications/Finder.app"
                            )
                        )
                        .resizable()
                        .frame(width: 13, height: 13)

                        Text(activeApp.name)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .frame(maxWidth: 58)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                if !expanded && !music.app.isEmpty {
                    MusicSpectrum(isPlaying: music.isPlaying)
                        .frame(width: 24, height: 12)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)

                Image(systemName: battery.symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        battery.low ? Color.orange : Color.white.opacity(0.92)
                    )

                Text(battery.percent.map { "\($0)%" } ?? "—")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.95))
                    .frame(minWidth: 25, alignment: .trailing)
            }
            .padding(.horizontal, 13)
            .frame(height: 34)
                
            if expanded {
                Rectangle()
                    .fill(.white.opacity(0.13))
                    .frame(height: 0.7)
                    .padding(.horizontal, 12)

                HStack(spacing: 9) {
                    Image(systemName: battery.charging ? "bolt.fill" : "battery.100percent")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(battery.charging ? Color.green.opacity(0.95) : .white.opacity(0.72))
                        .frame(width: 15)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(battery.charging ? "Mengisi daya" : "Menggunakan baterai")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.92))
                            Spacer(minLength: 4)
                            Text(battery.percent.map { "\($0)%" } ?? "—")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.13))
                                Capsule()
                                    .fill(battery.low ? Color.orange : (battery.charging ? Color.green.opacity(0.9) : .white.opacity(0.9)))
                                    .frame(width: geometry.size.width * CGFloat(battery.percent ?? 0) / 100)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                .padding(.horizontal, 13)
                .frame(height: 53)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))

HStack(spacing: 8) {
MusicArtworkView(music: music)

    VStack(alignment: .leading, spacing: 3) {
        Text(music.title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)

        Text(music.app.isEmpty ? music.artist : "\(music.artist) · \(music.app)")
            .font(.system(size: 9))
            .foregroundStyle(.white.opacity(0.65))
            .lineLimit(1)

        MusicSpectrum(isPlaying: music.isPlaying)
            .frame(height: 12)
    }

    Spacer(minLength: 2)

    Button {
        music.previousTrack()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            music = MusicInfo.read()
        }
    } label: {
        Image(systemName: "backward.end.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: 22, height: 26)
    }
    .buttonStyle(.plain)
    .disabled(music.app.isEmpty)

    Button {
        music.togglePlayback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            music = MusicInfo.read()
        }
    } label: {
        Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 27, height: 27)
            .background(.white.opacity(0.15), in: Circle())
    }
    .buttonStyle(.plain)
    .disabled(music.app.isEmpty)

    Button {
        music.nextTrack()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            music = MusicInfo.read()
        }
    } label: {
        Image(systemName: "forward.end.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: 22, height: 26)
    }
    .buttonStyle(.plain)
    .disabled(music.app.isEmpty)
}

.padding(.horizontal, 13)
.frame(height: 48)
.transition(.opacity)

VStack(spacing: 2) {
    Slider(
        value: $seekPosition,
        in: 0...max(music.duration, 1),
        onEditingChanged: { editing in
            isSeeking = editing

            if !editing {
                music.seek(to: seekPosition)
            }
        }
    )
    .controlSize(.mini)
    .tint(.green)

    HStack {
        Text(formatMusicTime(seekPosition))
        Spacer()
        Text(formatMusicTime(music.duration))
    }
    .font(.system(size: 10, design: .monospaced))
    .foregroundStyle(.secondary)
}
.padding(.horizontal, 12)
.padding(.bottom, 6)

HStack(spacing: 8) {
    Image(systemName: weather.symbol)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.white.opacity(0.9))
        .frame(width: 25)

    VStack(alignment: .leading, spacing: 2) {
        Text("Purwakarta, Jawa Barat")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)

        Text(weather.description)
            .font(.system(size: 9))
            .foregroundStyle(.white.opacity(0.65))
    }

    Spacer()

    if let temperature = weather.temperature {
        Text("\(temperature)°C")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
    } else {
        ProgressView()
            .controlSize(.small)
            .tint(.white)
    }
}
.padding(.horizontal, 13)
.frame(height: 38)
.transition(.opacity)
            }
        }
        .frame(width: expanded ? 320 : 224)

.background {
    ZStack {
        // Clear glass base: no material blur.
        RoundedRectangle(
            cornerRadius: expanded ? 25 : 18,
            style: .continuous
        )
        .fill(Color.white.opacity(0.035))

        // Main glass gradient: bright at the top, subtle depth below.
        RoundedRectangle(
            cornerRadius: expanded ? 25 : 18,
            style: .continuous
        )
        .fill(
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.23), location: 0.0),
                    .init(color: .white.opacity(0.09), location: 0.16),
                    .init(color: .white.opacity(0.025), location: 0.48),
                    .init(color: .black.opacity(0.13), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )

        // Subtle cool tint for a dimensional glass appearance.
        RoundedRectangle(
            cornerRadius: expanded ? 25 : 18,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.84, blue: 1.0)
                        .opacity(0.07),
                    .clear,
                    Color.black.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
        .clipShape(RoundedRectangle(cornerRadius: expanded ? 25 : 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: expanded ? 25 : 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(hovering ? 0.38 : 0.28), .white.opacity(0.07), .white.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        }

.overlay(alignment: .top) {
    Capsule()
        .fill(
            LinearGradient(
                colors: [
                    .white.opacity(0.32),
                    .white.opacity(0.12),
                    .white.opacity(0.02)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(width: expanded ? 100 : 66, height: 0.8)
        .padding(.top, 0.5)
        .opacity(0.75)
}
        .shadow(color: .black.opacity(0.32), radius: 14, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: expanded ? 25 : 18, style: .continuous))
        .onHover { hovering = $0 }
        .onTapGesture {
            withAnimation(.spring(response: 0.46, dampingFraction: 0.88)) {
                expanded.toggle()
            }
        }
        
        .onChange(of: expanded) { _, value in
            onExpansionChanged(value)
        }

        .onReceive(refresh) { _ in
            battery = BatteryInfo.read()
        }

        .onReceive(musicRefresh) { _ in
            let updatedMusic = MusicInfo.read()
            print("REFRESH duration:", updatedMusic.duration)
            print("REFRESH position:", updatedMusic.position)

            guard updatedMusic.duration > 0 else { return }

            music = updatedMusic

            if !isSeeking {
                seekPosition = updatedMusic.position
            }
        }
        .onReceive(activeAppRefresh) { _ in
            activeApp = ActiveAppInfo.read()
        }
        .task {
            await loadWeather()
        }
                .onReceive(weatherRefresh) { _ in
            Task {
                await loadWeather()
            }
        }
    }

    private func formatMusicTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else {
            return "0:00"
        }

        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60

        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
    }

    @MainActor
    private func loadWeather() async {
        guard let url = URL(string:
            "https://api.open-meteo.com/v1/forecast?latitude=-6.5569&longitude=107.4433&current=temperature_2m,weather_code&timezone=Asia%2FJakarta"
        ) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(
                WeatherResponse.self,
                from: data
            )

            weather = WeatherInfo(
                temperature: Int(response.current.temperature.rounded()),
                code: response.current.code
            )
        } catch {
            print("Gagal mengambil cuaca: \(error.localizedDescription)")
        }
    }
}

struct ActiveAppInfo {
    let name: String
    let bundleID: String

    static let current = ActiveAppInfo(
        name: "Finder",
        bundleID: "com.apple.finder"
    )

    static func read() -> ActiveAppInfo {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return .current
        }

        return ActiveAppInfo(
            name: app.localizedName ?? "Aplikasi",
            bundleID: app.bundleIdentifier ?? ""
        )
    }
}

struct MusicInfo {
    let app: String
    let title: String
    let artist: String
    let isPlaying: Bool
    let artworkURL: URL?
    let position: Double
    let duration: Double

    static let empty = MusicInfo(
        app: "",
        title: "Belum ada musik",
        artist: "Putar lagu di Spotify",
        isPlaying: false,
        artworkURL: nil,
        position: 0,
        duration: 0
    )

    static func read() -> MusicInfo {
        let running = !NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.spotify.client")
            .isEmpty

        guard running else { return .empty }

        let script = """
        tell application "Spotify"
            if player state is playing or player state is paused then
                set trackName to name of current track as string
                set artistName to artist of current track as string
                set playState to player state as string
                set artworkLink to artwork url of current track as string
                set trackPosition to player position as string
                set trackDuration to (duration of current track) / 1000
                return playState & "|||" & trackName & "|||" & artistName & "|||" & artworkLink & "|||" & trackPosition & "|||" & trackDuration
            end if
        end tell
        return ""
        """

        var error: NSDictionary?
        guard let result = NSAppleScript(source: script)?
            .executeAndReturnError(&error),
              let value = result.stringValue,
              !value.isEmpty else {
            return .empty
        }

        let parts = value.components(separatedBy: "|||")
        guard parts.count >= 6 else { return .empty }

        print("Spotify position:", parts[4])
        print("Spotify duration:", parts[5])

        return MusicInfo(
            app: "Spotify",
            title: parts[1],
            artist: parts[2],
            isPlaying: parts[0] == "playing",
            artworkURL: parts[3].isEmpty ? nil : URL(string: parts[3]),
            position: Double(parts[4].replacingOccurrences(of: ",", with: ".")) ?? 0,
            duration: Double(parts[5].replacingOccurrences(of: ",", with: ".")) ?? 0
        )
    }

    func togglePlayback() {
        runCommand("playpause")
    }

    func previousTrack() {
        runCommand("previous track")
    }

    func nextTrack() {
        runCommand("next track")
    }

func seek(to seconds: Double) {
    guard seconds.isFinite else { return }

    let target = max(0, seconds)

    let script = """
    tell application "Spotify"
        set player position to \(target)
    end tell
    """

    var error: NSDictionary?
    NSAppleScript(source: script)?.executeAndReturnError(&error)

    if let error {
        print("Spotify seek error: \(error)")
    } else {
        print("Spotify seek command executed: \(target)")
    }
}

    private func runCommand(_ command: String) {
        guard app == "Spotify" else { return }

        let script = """
        tell application "Spotify"
            \(command)
        end tell
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }
}

struct MusicArtworkView: View {
    let music: MusicInfo

    var body: some View {
        Group {
            if let url = music.artworkURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(
            RoundedRectangle(cornerRadius: 7)
        )
    }

    private var fallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(.white.opacity(0.12))

            Image(
                systemName: music.app == "Spotify"
                    ? "waveform"
                    : "music.note"
            )
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: 42, height: 42)
    }
}

struct WeatherInfo {
    let temperature: Int?
    let code: Int?

    static let loading = WeatherInfo(
        temperature: nil,
        code: nil
    )

    var description: String {
        guard let code else { return "Memuat cuaca..." }

        switch code {
        case 0: return "Cerah"
        case 1: return "Cerah sebagian"
        case 2: return "Berawan sebagian"
        case 3: return "Berawan"
        case 45, 48: return "Berkabut"
        case 51, 53, 55: return "Gerimis"
        case 61, 63, 65: return "Hujan"
        case 66, 67: return "Hujan beku"
        case 71, 73, 75, 77: return "Salju"
        case 80, 81, 82: return "Hujan singkat"
        case 85, 86: return "Hujan salju"
        case 95, 96, 99: return "Badai petir"
        default: return "Kondisi tidak diketahui"
        }
    }

    var symbol: String {
        guard let code else { return "cloud" }

        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

private struct WeatherResponse: Decodable {
    let current: CurrentWeather

    struct CurrentWeather: Decodable {
        let temperature: Double
        let code: Int

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case code = "weather_code"
        }
    }

    enum CodingKeys: String, CodingKey {
        case current
    }
}

struct MusicSpectrum: View {
    let isPlaying: Bool

    private let barCount = 7

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 0.10,
                paused: !isPlaying
            )
        ) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let wave = abs(
                        sin(time * 5.0 + Double(index) * 0.85)
                        * cos(time * 2.7 + Double(index) * 0.42)
                    )

                    Capsule()
                        .fill(.white.opacity(isPlaying ? 0.95 : 0.35))
                        .frame(
                            width: 2.5,
                            height: isPlaying
                                ? 3 + CGFloat(wave) * 7
                                : 3
                        )
                }
            }
            .frame(height: 12)
        }
    }
}

struct BatteryInfo {
    let percent: Int?
    let charging: Bool

    var low: Bool { (percent ?? 100) <= 20 }

    var symbol: String {
        guard let percent else { return "battery.0" }
        if charging { return "battery.100percent.bolt" }
        switch percent {
        case 0..<20: return "battery.25percent"
        case 20..<50: return "battery.50percent"
        case 50..<80: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    static func read() -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return BatteryInfo(percent: nil, charging: false)
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            let current = description[kIOPSCurrentCapacityKey] as? Int
            let maximum = description[kIOPSMaxCapacityKey] as? Int
            let state = description[kIOPSPowerSourceStateKey] as? String
            let percent: Int?
            if let current, let maximum, maximum > 0 {
                percent = Int((Double(current) / Double(maximum) * 100).rounded())
            } else {
                percent = nil
            }
            return BatteryInfo(percent: percent, charging: state == kIOPSACPowerValue)
        }
        return BatteryInfo(percent: nil, charging: false)
    }
}
