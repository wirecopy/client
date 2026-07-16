import AppKit
import SwiftUI
import WirecopyCore

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var server: String
    @State private var token: String
    @State private var expiresIn: Int

    init(model: AppModel) {
        self.model = model
        let environment = ProcessInfo.processInfo.environment
        let isPreview = environment["WIRECOPY_UI_PREVIEW"] != nil
        _server = State(initialValue: environment["WIRECOPY_SERVER"] ?? UserDefaults.standard.string(forKey: "serverURL") ?? "http://localhost:3000")
        _token = State(initialValue: isPreview ? (environment["WIRECOPY_TOKEN"] ?? "wc_preview_token") : ((try? KeychainStore().readToken()) ?? ""))
        _expiresIn = State(initialValue: environment["WIRECOPY_EXPIRES_IN"].flatMap(Int.init) ?? UserDefaults.standard.integer(forKey: "expiresIn").nonzero ?? 86_400)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Form {
                Section("Connection") {
                    TextField("Server", text: $server, prompt: Text("http://localhost:3000"))
                    SecureField("Device token", text: $token, prompt: Text("wc_live_…"))
                }

                Section {
                    Picker("New links expire after", selection: $expiresIn) {
                        Text("24 hours").tag(86_400)
                        Text("7 days").tag(604_800)
                        Text("30 days").tag(2_592_000)
                        Text("1 year").tag(31_536_000)
                    }
                } header: {
                    Text("Expiration")
                } footer: {
                    Text("You can revoke a link earlier from the menu-bar app or web dashboard.")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            if let message = model.connectionMessage {
                connectionStatus(message)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }

            Divider()
            actions
        }
        .font(WirecopyTheme.body())
        .foregroundStyle(WirecopyTheme.ink)
        .background(WirecopyTheme.canvas)
    }

    private var header: some View {
        HStack(spacing: 16) {
            HStack(spacing: 7) {
                Text("W/")
                    .font(WirecopyTheme.display(27, weight: .semibold))
                Text("wirecopy")
                    .font(WirecopyTheme.body(14, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Connection & retention")
                    .font(WirecopyTheme.display(22))
                Text("Connection and link defaults")
                    .font(WirecopyTheme.body(11))
                    .foregroundStyle(WirecopyTheme.inkMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func connectionStatus(_ message: String) -> some View {
        let isSuccess = message.hasPrefix("Connected") || message.hasPrefix("Saved")
        return HStack(spacing: 7) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "info.circle")
                .foregroundStyle(isSuccess ? WirecopyTheme.success : WirecopyTheme.inkMuted)
            Text(message).font(WirecopyTheme.body(11))
            Spacer()
        }
        .padding(9)
        .wirecopyPanel(isSuccess ? WirecopyTheme.mint : WirecopyTheme.lilac)
    }

    private var actions: some View {
        HStack(spacing: 9) {
            Button("Open Token Page") {
                let trimmedServer = server.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                if let url = URL(string: "\(trimmedServer)/device_tokens") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .tint(WirecopyTheme.inkMuted)

            Spacer()

            Button("Test Connection") {
                model.testConnection(server: server, token: token)
            }
            .tint(WirecopyTheme.ink)

            Button("Save") {
                model.saveConfiguration(server: server, token: token, expiresIn: expiresIn)
            }
            .buttonStyle(.borderedProminent)
            .tint(WirecopyTheme.peach)
            .disabled(token.isEmpty)
        }
        .controlSize(.regular)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

private extension Int {
    var nonzero: Int? { self == 0 ? nil : self }
}
