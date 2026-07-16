import AppKit
import Combine
import Foundation
import WirecopyCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var stage: PublishStage?
    @Published private(set) var errorMessage: String?
    @Published private(set) var history: [PublishedLink] = []
    @Published private(set) var isConfigured = false
    @Published private(set) var connectionMessage: String?

    private let historyStore = HistoryStore()
    private var task: Task<Void, Never>?
    private var completionResetTask: Task<Void, Never>?
    private var shortcutCancellable: AnyCancellable?

    var isWorking: Bool { stage != nil && stage != .complete }

    init(previewHistory: [PublishedLink]? = nil) {
        isConfigured = (try? WirecopyConfiguration.load()) != nil
        shortcutCancellable = NotificationCenter.default.publisher(for: .wirecopyShortcut)
            .sink { [weak self] _ in
                Task { @MainActor in self?.publishClipboard(presentErrors: true) }
            }
        if let previewHistory {
            history = previewHistory
        } else {
            Task { history = await historyStore.all() }
        }
    }

    func publishClipboard() {
        publishClipboard(presentErrors: false)
    }

    private func publishClipboard(presentErrors: Bool) {
        do {
            publish(try InputInspector.prepareClipboard(), presentErrors: presentErrors)
        } catch {
            fail(error, presentAlert: presentErrors)
        }
    }

    func publish(urls: [URL]) {
        do {
            publish(try InputInspector.prepare(urls: urls))
        } catch {
            fail(error)
        }
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Transmit"
        panel.message = "Choose one file or select several to package them into one deterministic ZIP."
        guard panel.runModal() == .OK else { return }
        publish(urls: panel.urls)
    }

    func copy(_ link: PublishedLink) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link.url.absoluteString, forType: .string)
    }

    private func completePublish(with link: PublishedLink) {
        copy(link)
        stage = .complete
        completionResetTask?.cancel()
        completionResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, self?.stage == .complete else { return }
            self?.stage = nil
        }
    }

    func open(_ link: PublishedLink) {
        NSWorkspace.shared.open(link.url)
    }

    func revoke(_ link: PublishedLink) {
        guard let remoteID = link.remoteID else {
            errorMessage = "Refresh this link in the web dashboard before revoking it."
            return
        }
        task = Task {
            do {
                let configuration = try WirecopyConfiguration.load()
                try await ManagedAPIClient(baseURL: configuration.serverURL, token: configuration.token).revoke(linkID: remoteID)
                await historyStore.remove(id: link.id)
                history.removeAll { $0.id == link.id }
            } catch { fail(error) }
        }
    }

    func saveConfiguration(server: String, token: String, expiresIn: Int) {
        guard let url = URL(string: server), ["http", "https"].contains(url.scheme?.lowercased()) else {
            connectionMessage = "Enter a valid HTTP or HTTPS server URL."
            return
        }
        do {
            try KeychainStore().saveToken(token.trimmingCharacters(in: .whitespacesAndNewlines))
            UserDefaults.standard.set(url.absoluteString, forKey: "serverURL")
            UserDefaults.standard.set(expiresIn, forKey: "expiresIn")
            isConfigured = !token.isEmpty
            connectionMessage = "Saved securely in Keychain."
        } catch {
            connectionMessage = error.localizedDescription
        }
    }

    func testConnection(server: String, token: String) {
        connectionMessage = "Testing…"
        Task {
            do {
                guard let url = URL(string: server) else { throw WirecopyError.missingConfiguration }
                let links = try await ManagedAPIClient(baseURL: url, token: token).links()
                connectionMessage = "Connected. \(links.count) recent link\(links.count == 1 ? "" : "s") available."
            } catch { connectionMessage = error.localizedDescription }
        }
    }

    func clearError() { errorMessage = nil }

    private func publish(_ asset: PreparedAsset, presentErrors: Bool = false) {
        guard !isWorking else { return }
        completionResetTask?.cancel()
        errorMessage = nil
        stage = .preparing
        task = Task {
            do {
                let configuration = try WirecopyConfiguration.load()
                let publisher = Publisher(api: ManagedAPIClient(baseURL: configuration.serverURL, token: configuration.token))
                let link = try await publisher.publish(asset, expiresIn: configuration.expiresIn) { [weak self] stage in
                    guard stage != .complete else { return }
                    Task { @MainActor in self?.stage = stage }
                }
                await historyStore.add(link)
                history = await historyStore.all()
                completePublish(with: link)
            } catch {
                asset.cleanup()
                fail(error, presentAlert: presentErrors)
            }
        }
    }

    private func fail(_ error: Error, presentAlert: Bool = false) {
        completionResetTask?.cancel()
        stage = nil
        errorMessage = error.localizedDescription
        NSSound.beep()
        guard presentAlert else { return }

        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Wirecopy couldn’t publish"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
