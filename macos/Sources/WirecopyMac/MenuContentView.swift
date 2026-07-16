import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WirecopyCore

struct MenuContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header
            WirecopyRule()
            if !model.isConfigured { setupCallout }
            actionArea
            if let error = model.errorMessage { errorCallout(error) }
            history
            footer
        }
        .font(WirecopyTheme.body())
        .foregroundStyle(WirecopyTheme.ink)
        .background(WirecopyTheme.canvas)
        .dropDestination(for: URL.self) { urls, _ in
            model.publish(urls: urls)
            return true
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                Text("W/")
                    .font(WirecopyTheme.display(22, weight: .semibold))
                Text("wirecopy")
                    .font(WirecopyTheme.body(13, weight: .semibold))
            }

            Spacer()

            if !model.isConfigured {
                HStack(spacing: 6) {
                    Circle()
                        .fill(WirecopyTheme.peach)
                        .frame(width: 6, height: 6)
                    Text("Setup required")
                }
                    .font(WirecopyTheme.body(11, weight: .medium))
                    .foregroundStyle(WirecopyTheme.inkMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var setupCallout: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "key.fill")
                .foregroundStyle(WirecopyTheme.inkMuted)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 5) {
                Text("Finish setting up Wirecopy")
                    .font(WirecopyTheme.display(18))
                Text("Add a device token in Settings. It will be stored in macOS Keychain.")
                    .font(WirecopyTheme.body(11))
                    .foregroundStyle(WirecopyTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Settings") { showSettings() }
                    .controlSize(.small)
                    .tint(WirecopyTheme.peach)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .wirecopyPanel(WirecopyTheme.lilac)
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    private var actionArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    WirecopySectionLabel(title: "Clipboard publishing")
                    Spacer()
                    HStack(spacing: 3) {
                        WirecopyKeycap(value: "⌃")
                        WirecopyKeycap(value: "⌥")
                        WirecopyKeycap(value: "C")
                    }
                }
                Text(actionTitle)
                    .font(WirecopyTheme.display(23))
                Text("Copy a file or image, then publish a private link.")
                    .font(WirecopyTheme.body(11))
                    .foregroundStyle(WirecopyTheme.inkMuted)
            }

            HStack(spacing: 8) {
                Button(action: model.publishClipboard) {
                    HStack(spacing: 7) {
                        Image(systemName: "doc.on.clipboard")
                        Text(buttonTitle)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(WirecopyTheme.peach)
                .controlSize(.large)
                .disabled(model.isWorking || !model.isConfigured)

                Button(action: model.chooseFiles) {
                    HStack(spacing: 7) {
                        Image(systemName: "folder.badge.plus")
                        Text("Choose Files…")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(WirecopyTheme.ink)
                .controlSize(.large)
                .disabled(model.isWorking || !model.isConfigured)
            }

            if case .uploading(let progress) = model.stage {
                ProgressView(value: progress)
                    .accessibilityLabel("Uploading")
            } else if model.isWorking {
                HStack(spacing: 7) {
                    ProgressView().controlSize(.small)
                    Text(model.stage?.label ?? "Preparing")
                        .font(WirecopyTheme.body(11))
                        .foregroundStyle(WirecopyTheme.inkMuted)
                }
            }
        }
        .padding(14)
    }

    private var actionTitle: String {
        model.isWorking ? (model.stage?.label ?? "Preparing") : "Publish from the clipboard"
    }

    private var buttonTitle: String {
        model.isWorking ? (model.stage?.label ?? "Preparing") : "Publish Clipboard"
    }

    private func errorCallout(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(WirecopyTheme.danger)
            VStack(alignment: .leading, spacing: 2) {
                Text("Couldn’t publish")
                    .font(WirecopyTheme.body(12, weight: .semibold))
                Text(message)
                    .font(WirecopyTheme.body(11))
                    .foregroundStyle(WirecopyTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button { model.clearError() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(WirecopyTheme.inkMuted)
            }
            .buttonStyle(.plain)
            .help("Dismiss")
        }
        .padding(11)
        .wirecopyPanel(WirecopyTheme.dangerTint)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 0) {
            WirecopyRule()
            HStack {
                WirecopySectionLabel(title: "Recent links")
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            if model.history.isEmpty {
                Text("Published links appear here.")
                    .font(WirecopyTheme.body(11))
                    .foregroundStyle(WirecopyTheme.inkMuted)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 11)
            } else {
                ForEach(Array(model.history.prefix(5).enumerated()), id: \.element.id) { index, link in
                    VStack(spacing: 0) {
                        if index > 0 { Divider().padding(.leading, 40) }
                        RecentLinkRow(
                            link: link,
                            onCopy: { model.copy(link) },
                            onOpen: { model.open(link) },
                            onRevoke: { model.revoke(link) }
                        )
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            WirecopyRule()
            HStack {
                Button("Settings…") { showSettings() }
                Spacer()
                Button("Quit Wirecopy") { NSApplication.shared.terminate(nil) }
            }
            .buttonStyle(.plain)
            .font(WirecopyTheme.body(11, weight: .medium))
            .foregroundStyle(WirecopyTheme.inkMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }

    private func showSettings() {
        openSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            let settingsWindow = NSApp.windows.first {
                $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" || $0.title.contains("Settings")
            }
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
    }
}

private struct RecentLinkRow: View {
    let link: PublishedLink
    let onCopy: () -> Void
    let onOpen: () -> Void
    let onRevoke: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCopied = false
    @State private var isConfirmingRevoke = false
    @State private var feedbackTask: Task<Void, Never>?
    @State private var revokeConfirmationTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "link")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WirecopyTheme.inkMuted)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(link.filename)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(WirecopyTheme.body(11, weight: .medium))
                WirecopyRelativeTime(date: link.createdAt)
                    .font(WirecopyTheme.body(10))
                    .foregroundStyle(WirecopyTheme.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                if isConfirmingRevoke {
                    Button(role: .destructive, action: confirmRevoke) {
                        Text("Delete?")
                            .font(WirecopyTheme.body(10, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(WirecopyTheme.danger)
                        .transition(
                            reduceMotion
                                ? .identity
                                : .opacity.combined(with: .scale(scale: 0.96, anchor: .trailing))
                        )
                        .help("Confirm link deletion")
                } else {
                    HStack(spacing: 7) {
                        Button(action: copyLink) {
                            ZStack {
                                if isCopied {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(WirecopyTheme.success)
                                        .transition(
                                            reduceMotion
                                                ? .identity
                                                : .opacity.combined(with: .scale(scale: 0.96))
                                        )
                                } else {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(WirecopyTheme.inkMuted)
                                        .transition(.opacity)
                                }
                            }
                            .frame(width: 18, height: 18)
                        }
                        .help(isCopied ? "Copied" : "Copy link")

                        Button(action: onOpen) {
                            Image(systemName: "arrow.up.forward.square")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(WirecopyTheme.inkMuted)
                                .frame(width: 18, height: 18)
                        }
                        .help("Open link")

                        Button(action: requestRevoke) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(WirecopyTheme.inkMuted)
                                .frame(width: 18, height: 18)
                        }
                        .disabled(link.remoteID == nil)
                        .help("Delete link")
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .frame(width: 68, height: 20)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .onDisappear {
            feedbackTask?.cancel()
            revokeConfirmationTask?.cancel()
        }
    }

    private func copyLink() {
        onCopy()
        feedbackTask?.cancel()

        if reduceMotion {
            isCopied = true
        } else {
            withAnimation(.easeOut(duration: 0.10)) {
                isCopied = true
            }
        }

        feedbackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            if reduceMotion {
                isCopied = false
            } else {
                withAnimation(.easeOut(duration: 0.08)) {
                    isCopied = false
                }
            }
        }
    }

    private func requestRevoke() {
        revokeConfirmationTask?.cancel()
        setRevokeConfirmation(true, duration: 0.10)
        revokeConfirmationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            setRevokeConfirmation(false, duration: 0.08)
        }
    }

    private func confirmRevoke() {
        revokeConfirmationTask?.cancel()
        onRevoke()
        setRevokeConfirmation(false, duration: 0.08)
    }

    private func setRevokeConfirmation(_ value: Bool, duration: Double) {
        if reduceMotion {
            isConfirmingRevoke = value
        } else {
            withAnimation(.easeOut(duration: duration)) {
                isConfirmingRevoke = value
            }
        }
    }
}

private struct WirecopyRelativeTime: View {
    let date: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Text(label(relativeTo: context.date))
        }
    }

    private func label(relativeTo now: Date) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))
        if elapsed < 60 { return "Just now" }

        let minutes = Int(elapsed / 60)
        if minutes < 60 { return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago" }

        let hours = minutes / 60
        if hours < 24 { return hours == 1 ? "1 hour ago" : "\(hours) hours ago" }

        let days = hours / 24
        if days < 7 { return days == 1 ? "1 day ago" : "\(days) days ago" }

        let weeks = days / 7
        return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
    }
}
