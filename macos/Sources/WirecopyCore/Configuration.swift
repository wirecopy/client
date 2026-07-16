import Foundation
import Security

public struct WirecopyConfiguration: Sendable {
    public let serverURL: URL
    public let token: String
    public let expiresIn: Int

    public init(serverURL: URL, token: String, expiresIn: Int = 86_400) {
        self.serverURL = serverURL
        self.token = token
        self.expiresIn = expiresIn
    }

    public static func load(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> WirecopyConfiguration {
        let defaults = UserDefaults.standard
        let rawServer = environment["WIRECOPY_SERVER"] ?? defaults.string(forKey: "serverURL") ?? "http://localhost:3000"
        let token: String
        if let environmentToken = environment["WIRECOPY_TOKEN"] {
            token = environmentToken
        } else {
            token = try KeychainStore().readToken()
        }
        let expiry = environment["WIRECOPY_EXPIRES_IN"].flatMap(Int.init) ?? defaults.integer(forKey: "expiresIn").nonzero ?? 86_400
        guard let serverURL = URL(string: rawServer), !token.isEmpty else { throw WirecopyError.missingConfiguration }
        return .init(serverURL: serverURL, token: token, expiresIn: expiry)
    }
}

public struct KeychainStore: Sendable {
    private let service: String
    private let account: String

    public init(service: String = "app.wirecopy.client", account: String = "managed-device-token") {
        self.service = service
        self.account = account
    }

    public func saveToken(_ token: String) throws {
        let query = baseQuery
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = Data(token.utf8)
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    public func readToken() throws -> String {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw KeychainError(status: status)
        }
        return token
    }

    public func deleteToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

public struct KeychainError: LocalizedError {
    let status: OSStatus
    public var errorDescription: String? { SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)" }
}

private extension Int {
    var nonzero: Int? { self == 0 ? nil : self }
}
