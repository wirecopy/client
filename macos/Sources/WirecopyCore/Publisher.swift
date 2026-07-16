import Foundation

public struct Publisher: Sendable {
    private let api: any ManagedAPI

    public init(api: any ManagedAPI) {
        self.api = api
    }

    public func publish(
        _ asset: PreparedAsset,
        expiresIn: Int,
        progress: @escaping @Sendable (PublishStage) -> Void = { _ in }
    ) async throws -> PublishedLink {
        defer { asset.cleanup() }
        progress(.creatingIntent)
        var intent = try await api.createIntent(
            filename: asset.filename,
            contentType: asset.contentType,
            byteSize: asset.byteSize,
            expiresIn: expiresIn
        )
        guard let grant = intent.upload else { throw WirecopyError.invalidServerResponse }

        try await api.upload(fileURL: asset.fileURL, grant: grant) { value in
            progress(.uploading(value))
        }
        progress(.scanning)
        intent = try await api.completeIntent(id: intent.id)
        if intent.state == "quarantined" {
            for attempt in 0..<30 {
                try await Task.sleep(for: .milliseconds(500 + (attempt * 50)))
                intent = try await api.intent(id: intent.id)
                if intent.state == "available" || intent.state == "rejected" { break }
            }
        }
        guard intent.state == "available", let link = intent.link else {
            if let failure = intent.error { throw WirecopyError.api(code: failure.code, message: failure.message ?? failure.code) }
            throw WirecopyError.scanTimedOut
        }

        let remoteID = try? await api.links().first(where: { $0.url == link.url })?.id
        progress(.complete)
        return PublishedLink(
            remoteID: remoteID,
            url: link.url,
            filename: asset.filename,
            byteSize: asset.byteSize,
            expiresAt: link.expiresAt
        )
    }
}
