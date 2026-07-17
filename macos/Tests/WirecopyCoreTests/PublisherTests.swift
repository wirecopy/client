import Foundation
import Testing

@testable import WirecopyCore

@Test func publisherRunsManagedLifecycleAndReturnsRemoteIdentity() async throws {
    let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try Data("payload".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    let api = FakeManagedAPI()
    let stages = StageRecorder()
    let asset = PreparedAsset(fileURL: file, filename: "payload.txt", contentType: "text/plain", byteSize: 7)

    let published = try await Publisher(api: api).publish(asset, expiresIn: 86_400) { stage in
        stages.append(stage)
    }

    #expect(published.remoteID == 44)
    #expect(published.filename == "payload.txt")
    #expect(published.url.absoluteString == "https://wirecopy.test/d/test")
    #expect(await api.didUpload)
    #expect(await api.didComplete)
    #expect(stages.values == [
        .creatingIntent,
        .uploading(0.25),
        .uploading(1),
        .scanning,
        .complete
    ])
}

private final class StageRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [PublishStage] = []

    func append(_ value: PublishStage) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }

    var values: [PublishStage] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

private actor FakeManagedAPI: ManagedAPI {
    private(set) var didUpload = false
    private(set) var didComplete = false
    private let linkURL = URL(string: "https://wirecopy.test/d/test")!

    func createIntent(filename: String, contentType: String, byteSize: Int64, expiresIn: Int) async throws -> UploadIntent {
        UploadIntent(
            id: "intent", state: "uploading", filename: filename, contentType: contentType,
            byteSize: byteSize, expiresAt: .now.addingTimeInterval(Double(expiresIn)), error: nil, link: nil,
            upload: UploadGrant(url: URL(string: "https://storage.test/object")!, method: "PUT", headers: ["Content-Type": contentType])
        )
    }

    func upload(fileURL: URL, grant: UploadGrant, progress: @escaping @Sendable (Double) -> Void) async throws {
        didUpload = true
        progress(0.25)
        progress(1)
    }

    func completeIntent(id: String) async throws -> UploadIntent {
        didComplete = true
        return availableIntent
    }

    func intent(id: String) async throws -> UploadIntent { availableIntent }

    func links() async throws -> [ManagedLink] {
        [ManagedLink(
            id: 44, url: linkURL, filename: "payload.txt", byteSize: 7, contentType: "text/plain",
            accessCount: 0, lastAccessedAt: nil, expiresAt: .now.addingTimeInterval(86_400),
            revokedAt: nil, createdAt: .now
        )]
    }

    func revoke(linkID: Int) async throws {}

    func publishSite(archiveURL: URL, expiresIn: Int, progress: @escaping @Sendable (Double) -> Void) async throws -> PublishedSite {
        progress(1)
        return PublishedSite(
            id: 1,
            state: "published",
            name: "site",
            url: URL(string: "https://s-test.artifacts.example")!,
            byteSize: 7,
            fileCount: 1,
            expiresAt: .now.addingTimeInterval(Double(expiresIn))
        )
    }

    private var availableIntent: UploadIntent {
        UploadIntent(
            id: "intent", state: "available", filename: "payload.txt", contentType: "text/plain", byteSize: 7,
            expiresAt: .now.addingTimeInterval(86_400), error: nil,
            link: UploadLink(url: linkURL, expiresAt: .now.addingTimeInterval(86_400)), upload: nil
        )
    }
}
