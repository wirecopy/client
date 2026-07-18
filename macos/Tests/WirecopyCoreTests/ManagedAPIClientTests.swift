import Foundation
import Testing

@testable import WirecopyCore

@Test func publishedSiteDecodesStorageWhenPresent() throws {
    let json = Data("""
    {
      "id": 7,
      "state": "published",
      "name": "site",
      "url": "https://s-abc.example",
      "storage": "byos",
      "byte_size": 42,
      "file_count": 3,
      "expires_at": "2026-01-01T00:00:00Z"
    }
    """.utf8)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let site = try decoder.decode(PublishedSite.self, from: json)

    #expect(site.storage == "byos")
}

@Test func publishedSiteDecodesWithoutStorageFromOlderServer() throws {
    let json = Data("""
    {
      "id": 7,
      "state": "published",
      "name": "site",
      "url": "https://s-abc.example",
      "byte_size": 42,
      "file_count": 3,
      "expires_at": "2026-01-01T00:00:00Z"
    }
    """.utf8)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let site = try decoder.decode(PublishedSite.self, from: json)

    #expect(site.storage == nil)
}

@Test func multipartBodyEmitsStoragePartWhenPresent() throws {
    let archive = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).zip")
    try Data("payload".utf8).write(to: archive)
    defer { try? FileManager.default.removeItem(at: archive) }

    let requestURL = try MultipartFile.build(archiveURL: archive, expiresIn: 86_400, storage: "byos", boundary: "b")
    defer { try? FileManager.default.removeItem(at: requestURL) }
    let body = String(decoding: try Data(contentsOf: requestURL), as: UTF8.self)

    #expect(body.contains("name=\"site[storage]\""))
    #expect(body.contains("\r\n\r\nbyos\r\n"))
}

@Test func multipartBodyOmitsStoragePartWhenAbsent() throws {
    let archive = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).zip")
    try Data("payload".utf8).write(to: archive)
    defer { try? FileManager.default.removeItem(at: archive) }

    let requestURL = try MultipartFile.build(archiveURL: archive, expiresIn: 86_400, storage: nil, boundary: "b")
    defer { try? FileManager.default.removeItem(at: requestURL) }
    let body = String(decoding: try Data(contentsOf: requestURL), as: UTF8.self)

    #expect(!body.contains("site[storage]"))
}
