import Foundation

public protocol ManagedAPI: Sendable {
    func createIntent(filename: String, contentType: String, byteSize: Int64, expiresIn: Int) async throws -> UploadIntent
    func upload(fileURL: URL, grant: UploadGrant, progress: @escaping @Sendable (Double) -> Void) async throws
    func completeIntent(id: String) async throws -> UploadIntent
    func intent(id: String) async throws -> UploadIntent
    func links() async throws -> [ManagedLink]
    func revoke(linkID: Int) async throws
    func publishSite(archiveURL: URL, expiresIn: Int, storage: String?, progress: @escaping @Sendable (Double) -> Void) async throws -> PublishedSite
}

public final class ManagedAPIClient: ManagedAPI, @unchecked Sendable {
    public let baseURL: URL
    private let token: String
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(baseURL: URL, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
        decoder.dateDecodingStrategy = .iso8601
    }

    public func createIntent(filename: String, contentType: String, byteSize: Int64, expiresIn: Int) async throws -> UploadIntent {
        struct Body: Encodable {
            struct Upload: Encodable {
                let filename: String
                let contentType: String
                let byteSize: Int64
                let expiresIn: Int

                enum CodingKeys: String, CodingKey {
                    case filename
                    case contentType = "content_type"
                    case byteSize = "byte_size"
                    case expiresIn = "expires_in"
                }
            }
            let upload: Upload
        }

        return try await request(
            path: "/api/v1/upload_intents",
            method: "POST",
            body: encoder.encode(Body(upload: .init(filename: filename, contentType: contentType, byteSize: byteSize, expiresIn: expiresIn)))
        )
    }

    public func upload(fileURL: URL, grant: UploadGrant, progress: @escaping @Sendable (Double) -> Void) async throws {
        var request = URLRequest(url: grant.url)
        request.httpMethod = grant.method
        grant.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let delegate = UploadProgressDelegate(progress: progress)
        let (_, response) = try await session.upload(for: request, fromFile: fileURL, delegate: delegate)
        guard let http = response as? HTTPURLResponse else { throw WirecopyError.invalidServerResponse }
        guard (200..<300).contains(http.statusCode) else { throw WirecopyError.uploadRejected(status: http.statusCode) }
    }

    public func completeIntent(id: String) async throws -> UploadIntent {
        try await request(path: "/api/v1/upload_intents/\(id)/complete", method: "POST", body: Data("{}".utf8))
    }

    public func intent(id: String) async throws -> UploadIntent {
        try await request(path: "/api/v1/upload_intents/\(id)")
    }

    public func links() async throws -> [ManagedLink] {
        struct Response: Decodable { let links: [ManagedLink] }
        let response: Response = try await request(path: "/api/v1/links")
        return response.links
    }

    public func revoke(linkID: Int) async throws {
        let _: EmptyResponse = try await request(path: "/api/v1/links/\(linkID)", method: "DELETE")
    }

    public func publishSite(archiveURL: URL, expiresIn: Int, storage: String? = nil, progress: @escaping @Sendable (Double) -> Void) async throws -> PublishedSite {
        let boundary = "wirecopy-\(UUID().uuidString)"
        let multipartURL = try MultipartFile.build(archiveURL: archiveURL, expiresIn: expiresIn, storage: storage, boundary: boundary)
        defer { try? FileManager.default.removeItem(at: multipartURL) }

        guard let url = URL(string: "/api/v1/sites", relativeTo: baseURL) else { throw WirecopyError.invalidServerResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let delegate = UploadProgressDelegate(progress: progress)
        let (data, response) = try await session.upload(for: request, fromFile: multipartURL, delegate: delegate)
        guard let http = response as? HTTPURLResponse else { throw WirecopyError.invalidServerResponse }
        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw WirecopyError.api(
                code: envelope?.error.code ?? "http_\(http.statusCode)",
                message: envelope?.error.message ?? "Wirecopy site publication failed (HTTP \(http.statusCode))."
            )
        }
        return try decoder.decode(PublishedSite.self, from: data)
    }

    private func request<Response: Decodable>(path: String, method: String = "GET", body: Data? = nil) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw WirecopyError.invalidServerResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WirecopyError.invalidServerResponse }
        if http.statusCode == 204, Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw WirecopyError.api(
                code: envelope?.error.code ?? "http_\(http.statusCode)",
                message: envelope?.error.message ?? "Wirecopy request failed (HTTP \(http.statusCode))."
            )
        }
        return try decoder.decode(Response.self, from: data)
    }
}

enum MultipartFile {
    static func build(archiveURL: URL, expiresIn: Int, storage: String? = nil, boundary: String) throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory.appending(path: "wirecopy-site-request-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: outputURL)
        defer { try? output.close() }

        try write("--\(boundary)\r\nContent-Disposition: form-data; name=\"site[mode]\"\r\n\r\nsite\r\n", to: output)
        try write("--\(boundary)\r\nContent-Disposition: form-data; name=\"site[expires_in]\"\r\n\r\n\(expiresIn)\r\n", to: output)
        if let storage {
            try write("--\(boundary)\r\nContent-Disposition: form-data; name=\"site[storage]\"\r\n\r\n\(storage)\r\n", to: output)
        }

        let filename = archiveURL.lastPathComponent.replacingOccurrences(of: "\"", with: "_")
        let contentType = archiveURL.pathExtension.lowercased() == "zip" ? "application/zip" : "text/html"
        try write("--\(boundary)\r\nContent-Disposition: form-data; name=\"site[archive]\"; filename=\"\(filename)\"\r\nContent-Type: \(contentType)\r\n\r\n", to: output)

        let input = try FileHandle(forReadingFrom: archiveURL)
        defer { try? input.close() }
        while let chunk = try input.read(upToCount: 64 * 1024), !chunk.isEmpty {
            try output.write(contentsOf: chunk)
        }
        try write("\r\n--\(boundary)--\r\n", to: output)
        return outputURL
    }

    private static func write(_ value: String, to handle: FileHandle) throws {
        try handle.write(contentsOf: Data(value.utf8))
    }
}

private struct APIErrorEnvelope: Decodable {
    struct Detail: Decodable { let code: String; let message: String }
    let error: Detail
}

private struct EmptyResponse: Codable {}

private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let progress: @Sendable (Double) -> Void

    init(progress: @escaping @Sendable (Double) -> Void) {
        self.progress = progress
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard totalBytesExpectedToSend > 0 else { return }
        progress(min(1, Double(totalBytesSent) / Double(totalBytesExpectedToSend)))
    }
}
