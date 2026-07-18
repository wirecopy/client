import Foundation

public struct UploadGrant: Codable, Sendable {
    public let url: URL
    public let method: String
    public let headers: [String: String]
}

public struct UploadLink: Codable, Sendable {
    public let url: URL
    public let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case url
        case expiresAt = "expires_at"
    }
}

public struct UploadFailure: Codable, Sendable {
    public let code: String
    public let message: String?
}

public struct UploadIntent: Codable, Sendable {
    public let id: String
    public let state: String
    public let filename: String
    public let contentType: String
    public let byteSize: Int64
    public let expiresAt: Date
    public let error: UploadFailure?
    public let link: UploadLink?
    public let upload: UploadGrant?

    enum CodingKeys: String, CodingKey {
        case id, state, filename, error, link, upload
        case contentType = "content_type"
        case byteSize = "byte_size"
        case expiresAt = "expires_at"
    }
}

public struct ManagedLink: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let url: URL
    public let filename: String
    public let byteSize: Int64
    public let contentType: String
    public let accessCount: Int
    public let lastAccessedAt: Date?
    public let expiresAt: Date
    public let revokedAt: Date?
    public let createdAt: Date

    public var isAvailable: Bool { revokedAt == nil && expiresAt > .now }

    enum CodingKeys: String, CodingKey {
        case id, url, filename
        case byteSize = "byte_size"
        case contentType = "content_type"
        case accessCount = "access_count"
        case lastAccessedAt = "last_accessed_at"
        case expiresAt = "expires_at"
        case revokedAt = "revoked_at"
        case createdAt = "created_at"
    }
}

public struct PublishedSite: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let state: String
    public let name: String
    public let url: URL
    public let storage: String?
    public let byteSize: Int64
    public let fileCount: Int
    public let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id, state, name, url, storage
        case byteSize = "byte_size"
        case fileCount = "file_count"
        case expiresAt = "expires_at"
    }
}

public struct PreparedSite: Sendable {
    public let archiveURL: URL
    public let removeAfterUse: Bool

    public init(archiveURL: URL, removeAfterUse: Bool) {
        self.archiveURL = archiveURL
        self.removeAfterUse = removeAfterUse
    }

    public func cleanup() {
        guard removeAfterUse else { return }
        try? FileManager.default.removeItem(at: archiveURL)
    }
}

public struct PublishedLink: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let remoteID: Int?
    public let url: URL
    public let filename: String
    public let byteSize: Int64
    public let expiresAt: Date
    public let createdAt: Date

    public init(remoteID: Int?, url: URL, filename: String, byteSize: Int64, expiresAt: Date, createdAt: Date = .now) {
        self.id = UUID()
        self.remoteID = remoteID
        self.url = url
        self.filename = filename
        self.byteSize = byteSize
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
}

public struct PreparedAsset: Sendable {
    public let fileURL: URL
    public let filename: String
    public let contentType: String
    public let byteSize: Int64
    public let removeAfterUse: Bool

    public init(fileURL: URL, filename: String, contentType: String, byteSize: Int64, removeAfterUse: Bool = false) {
        self.fileURL = fileURL
        self.filename = filename
        self.contentType = contentType
        self.byteSize = byteSize
        self.removeAfterUse = removeAfterUse
    }

    public func cleanup() {
        guard removeAfterUse else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}

public enum PublishStage: Equatable, Sendable {
    case preparing
    case creatingIntent
    case uploading(Double)
    case scanning
    case complete

    public var label: String {
        switch self {
        case .preparing: "Preparing"
        case .creatingIntent: "Authorizing"
        case .uploading(let progress): "Uploading \(Int(progress * 100))%"
        case .scanning: "Safety check"
        case .complete: "Link copied"
        }
    }
}

public enum WirecopyError: LocalizedError, Sendable {
    case missingConfiguration
    case noSupportedClipboardContent
    case unsupportedDirectory(URL)
    case unreadableFile(URL)
    case invalidServerResponse
    case api(code: String, message: String)
    case uploadRejected(status: Int)
    case scanTimedOut
    case invalidSite(String)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration: "Add the local server and a device token in Wirecopy Settings."
        case .noSupportedClipboardContent: "No image or file found on the clipboard. Clipboard text is ignored."
        case .unsupportedDirectory: "Folders are not uploaded by the file-link workflow yet."
        case .unreadableFile(let url): "Wirecopy could not read \(url.lastPathComponent)."
        case .invalidServerResponse: "The Wirecopy service returned an invalid response."
        case .api(_, let message): message
        case .uploadRejected(let status): "Object storage rejected the upload (HTTP \(status))."
        case .scanTimedOut: "The safety check is taking longer than expected. The file remains quarantined."
        case .invalidSite(let message): message
        }
    }
}
