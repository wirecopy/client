import AppKit
import SwiftUI
import WirecopyCore

@main
struct WirecopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(model: model)
                .frame(width: 380)
        } label: {
            MenuBarStatusIcon(stage: model.stage, hasError: model.errorMessage != nil)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
                .frame(width: 520, height: 420)
        }
    }
}

private struct MenuBarStatusIcon: View {
    let stage: PublishStage?
    let hasError: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            statusSymbol
                .id(statusKey)
                .transition(
                    reduceMotion
                        ? .identity
                        : .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity
                        )
                )
        }
            .frame(width: 16, height: 16)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.10), value: statusKey)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var statusSymbol: some View {
        if hasError {
            Image(systemName: "exclamationmark.triangle.fill")
        } else {
            switch stage {
            case .none:
                Text("W/")
                    .font(WirecopyTheme.display(12, weight: .semibold))
                    .tracking(-1.2)
            case .preparing:
                Image(systemName: "clock.fill")
            case .creatingIntent, .scanning:
                Image(systemName: "ellipsis.circle.fill")
            case .uploading(let progress):
                MenuBarUploadProgress(progress: progress)
            case .complete:
                Image(systemName: "checkmark.circle.fill")
            }
        }
    }

    private var statusKey: StatusKey {
        if hasError { return .failure }
        switch stage {
        case .none: return .idle
        case .preparing, .creatingIntent, .scanning: return .processing
        case .uploading: return .uploading
        case .complete: return .complete
        }
    }

    private var accessibilityLabel: String {
        if hasError { return "Wirecopy upload failed" }
        switch stage {
        case .none: return "Wirecopy"
        case .preparing: return "Wirecopy is preparing the file"
        case .creatingIntent: return "Wirecopy is authorizing the upload"
        case .uploading: return "Wirecopy is uploading"
        case .scanning: return "Wirecopy is checking the upload"
        case .complete: return "Wirecopy link copied"
        }
    }

    private var accessibilityValue: String {
        guard case .uploading(let progress) = stage else { return "" }
        return "\(Int(min(max(progress, 0), 1) * 100)) percent"
    }

    private enum StatusKey: Hashable {
        case idle
        case processing
        case uploading
        case complete
        case failure
    }
}

private struct MenuBarUploadProgress: View {
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.24), lineWidth: 1.5)
                Circle()
                    .trim(from: 0, to: max(0.08, clampedProgress))
                    .stroke(
                        Color.primary,
                        style: StrokeStyle(lineWidth: 1.7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(rotation(at: context.date)))
                    .animation(reduceMotion ? nil : .linear(duration: 0.08), value: clampedProgress)
            }
        }
        .frame(width: 14, height: 14)
    }

    private func rotation(at date: Date) -> Double {
        guard !reduceMotion else { return -90 }
        let cycle = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.85) / 0.85
        return (cycle * 360) - 90
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var shortcut: GlobalShortcut?
    private var previewWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Wirecopy application did finish launching")
        if ProcessInfo.processInfo.environment["WIRECOPY_UI_PREVIEW"] == nil {
            NSApp.setActivationPolicy(.accessory)
        } else {
            applyPreviewAppearance()
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            showPreview(mode: ProcessInfo.processInfo.environment["WIRECOPY_UI_PREVIEW"] ?? "menu")
        }
        shortcut = GlobalShortcut()
        shortcut?.register()
    }

    private func applyPreviewAppearance() {
        MainActor.assumeIsolated {
            switch ProcessInfo.processInfo.environment["WIRECOPY_UI_APPEARANCE"] {
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
            default:
                break
            }
        }
    }

    @MainActor
    private func showPreview(mode: String) {
        let model = AppModel(previewHistory: mode == "menu" ? previewHistory : nil)
        let rootView: AnyView
        let contentSize: NSSize

        if mode == "settings" {
            rootView = AnyView(SettingsView(model: model).frame(width: 520, height: 420))
            contentSize = NSSize(width: 520, height: 420)
        } else {
            rootView = AnyView(MenuContentView(model: model).frame(width: 380).fixedSize())
            contentSize = NSSize(width: 380, height: 560)
        }

        let controller = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: controller)
        window.title = mode == "settings" ? "Wirecopy Settings Preview" : "Wirecopy Menu Preview"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(contentSize)
        window.center()
        window.makeKeyAndOrderFront(nil)
        previewWindow = window
    }

    private var previewHistory: [PublishedLink] {
        [
            PublishedLink(
                remoteID: 101,
                url: URL(string: "https://wirecopy.test/d/presentation")!,
                filename: "wirecopy-quarterly-presentation-with-review-comments-final-v12.pdf",
                byteSize: 24_000_000,
                expiresAt: .now.addingTimeInterval(86_400),
                createdAt: .now.addingTimeInterval(-240)
            ),
            PublishedLink(
                remoteID: 102,
                url: URL(string: "https://wirecopy.test/d/screenshot")!,
                filename: "finder-screenshot.png",
                byteSize: 1_200_000,
                expiresAt: .now.addingTimeInterval(86_400),
                createdAt: .now.addingTimeInterval(-20)
            ),
            PublishedLink(
                remoteID: 103,
                url: URL(string: "https://wirecopy.test/d/log")!,
                filename: "deployment-output.log",
                byteSize: 84_000,
                expiresAt: .now.addingTimeInterval(86_400),
                createdAt: .now.addingTimeInterval(-3_900)
            )
        ]
    }
}

extension Notification.Name {
    static let wirecopyShortcut = Notification.Name("app.wirecopy.globalShortcut")
}
