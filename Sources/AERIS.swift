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
            let newWidth: CGFloat = expanded ? 246 : 224
            let newHeight: CGFloat = expanded ? 88 : 34
            let topEdge = panel.frame.maxY
            let originX = panel.frame.midX - newWidth / 2

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

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let refresh = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(now, format: .dateTime.hour().minute())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.96))
                    .frame(minWidth: 37, alignment: .leading)

                Spacer(minLength: 4)

                Image(systemName: battery.symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(battery.low ? Color.orange : Color.white.opacity(0.92))

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
            }
        }
        .frame(width: expanded ? 246 : 224)

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
        .onChange(of: expanded) { _, value in onExpansionChanged(value) }
        .onReceive(clock) { now = $0 }
        .onReceive(refresh) { _ in battery = BatteryInfo.read() }
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
