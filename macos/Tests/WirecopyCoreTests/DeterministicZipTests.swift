import Foundation
import Testing

@testable import WirecopyCore

@Test func deterministicZipIsStableAndSorted() throws {
    let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let first = root.appending(path: "zeta.txt")
    let second = root.appending(path: "alpha.txt")
    try Data("zeta".utf8).write(to: first)
    try Data("alpha".utf8).write(to: second)
    let archiveA = root.appending(path: "a.zip")
    let archiveB = root.appending(path: "b.zip")

    try DeterministicZip.create(from: [first, second], at: archiveA)
    try DeterministicZip.create(from: [second, first], at: archiveB)

    #expect(try Data(contentsOf: archiveA) == Data(contentsOf: archiveB))
    let bytes = try Data(contentsOf: archiveA)
    #expect(bytes.range(of: Data("alpha.txt".utf8)) != nil)
    #expect(bytes.range(of: Data("zeta.txt".utf8)) != nil)
}

@Test func duplicateFilenamesReceiveStableSuffixes() throws {
    let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let left = root.appending(path: "left", directoryHint: .isDirectory)
    let right = root.appending(path: "right", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: left, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: right, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let one = left.appending(path: "report.txt")
    let two = right.appending(path: "report.txt")
    try Data("one".utf8).write(to: one)
    try Data("two".utf8).write(to: two)
    let archive = root.appending(path: "reports.zip")

    try DeterministicZip.create(from: [one, two], at: archive)

    let bytes = try Data(contentsOf: archive)
    #expect(bytes.range(of: Data("report.txt".utf8)) != nil)
    #expect(bytes.range(of: Data("report-2.txt".utf8)) != nil)
}

@Test func siteFolderPreservesNestedPathsAndRequiresRootIndex() throws {
    let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let assets = root.appending(path: "assets", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try Data("<script src=\"assets/app.js\"></script>".utf8).write(to: root.appending(path: "index.html"))
    try Data("console.log('wirecopy')".utf8).write(to: assets.appending(path: "app.js"))
    let archive = root.appending(path: "site.zip")

    try DeterministicZip.createSite(from: root, at: archive)

    let bytes = try Data(contentsOf: archive)
    #expect(bytes.range(of: Data("index.html".utf8)) != nil)
    #expect(bytes.range(of: Data("assets/app.js".utf8)) != nil)
}
