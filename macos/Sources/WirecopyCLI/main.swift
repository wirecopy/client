import Foundation
import WirecopyCore

@main
struct WirecopyCLI {
    static func main() async {
        do {
            try await run(Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("wirecopy: \(error.localizedDescription)\n".utf8))
            Foundation.exit(exitCode(for: error))
        }
    }

    private static func run(_ arguments: [String]) async throws {
        guard let command = arguments.first, !["help", "--help", "-h"].contains(command) else {
            print(usage)
            return
        }
        switch command {
        case "configure":
            try configure(Array(arguments.dropFirst()))
        case "publish", "send":
            try await publish(Array(arguments.dropFirst()))
        case "links":
            try await links(Array(arguments.dropFirst()))
        default:
            throw CLIError.usage("Unknown command: \(command)")
        }
    }

    private static func configure(_ arguments: [String]) throws {
        let options = Options(arguments)
        guard let server = options.value("--server"), let url = URL(string: server),
              let token = options.value("--token"), !token.isEmpty else {
            throw CLIError.usage("configure requires --server URL and --token wc_live_…")
        }
        try KeychainStore().saveToken(token)
        UserDefaults.standard.set(url.absoluteString, forKey: "serverURL")
        if let expiry = options.value("--expires").flatMap(Int.init) { UserDefaults.standard.set(expiry, forKey: "expiresIn") }
        print("Configured \(url.absoluteString). Token stored in Keychain.")
    }

    private static func publish(_ arguments: [String]) async throws {
        let options = Options(arguments)
        let asset: PreparedAsset
        if options.has("--clipboard") {
            asset = try InputInspector.prepareClipboard()
        } else {
            let paths = options.positionals.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
            guard !paths.isEmpty else { throw CLIError.usage("publish requires one or more paths, or --clipboard") }
            asset = try InputInspector.prepare(urls: paths)
        }

        let configuration = try WirecopyConfiguration.load()
        let expiresIn = options.value("--expires").flatMap(Int.init) ?? configuration.expiresIn
        let format = options.has("--json") ? OutputFormat.json : OutputFormat(rawValue: options.value("--format") ?? "raw") ?? .raw
        let publisher = Publisher(api: ManagedAPIClient(baseURL: configuration.serverURL, token: configuration.token))
        let link = try await publisher.publish(asset, expiresIn: expiresIn) { stage in
            FileHandle.standardError.write(Data("\r\(stage.label.padding(toLength: 32, withPad: " ", startingAt: 0))".utf8))
        }
        FileHandle.standardError.write(Data("\n".utf8))
        print(try OutputFormatter.format(link, as: format))
    }

    private static func links(_ arguments: [String]) async throws {
        let configuration = try WirecopyConfiguration.load()
        let api = ManagedAPIClient(baseURL: configuration.serverURL, token: configuration.token)
        if arguments.first == "revoke" {
            guard arguments.count == 2, let id = Int(arguments[1]) else { throw CLIError.usage("links revoke requires a numeric link ID") }
            try await api.revoke(linkID: id)
            print("Revoked link \(id).")
            return
        }

        let links = try await api.links()
        if arguments.contains("--json") {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys]
            print(String(decoding: try encoder.encode(links), as: UTF8.self))
        } else if links.isEmpty {
            print("No links.")
        } else {
            for link in links {
                let status = link.isAvailable ? "live" : "ended"
                print("\(link.id)\t\(status)\t\(link.filename)\t\(link.url.absoluteString)")
            }
        }
    }

    private static func exitCode(for error: Error) -> Int32 {
        switch error {
        case is CLIError: 64
        case WirecopyError.missingConfiguration: 78
        case WirecopyError.api: 69
        default: 1
        }
    }

    private static let usage = """
    Wirecopy — turn files into controlled links

    Usage:
      wirecopy configure --server http://localhost:3000 --token wc_live_… [--expires 86400]
      wirecopy publish <path> [more paths] [--expires seconds] [--format raw|markdown|html|json]
      wirecopy publish --clipboard [--json]
      wirecopy links [--json]
      wirecopy links revoke <id>

    Environment overrides: WIRECOPY_SERVER, WIRECOPY_TOKEN, WIRECOPY_EXPIRES_IN
    """
}

private struct Options {
    let arguments: [String]

    init(_ arguments: [String]) { self.arguments = arguments }

    var positionals: [String] {
        var result: [String] = []
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if ["--server", "--token", "--expires", "--format"].contains(argument) { index += 2; continue }
            if argument.hasPrefix("--") { index += 1; continue }
            result.append(argument)
            index += 1
        }
        return result
    }

    func has(_ name: String) -> Bool { arguments.contains(name) }

    func value(_ name: String) -> String? {
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

private enum CLIError: LocalizedError {
    case usage(String)
    var errorDescription: String? {
        switch self { case .usage(let message): "\(message)\nRun 'wirecopy --help' for usage." }
    }
}
