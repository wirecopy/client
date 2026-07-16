import Foundation
import Testing

@testable import WirecopyCore

@Test func outputFormatsAreStableAndEscaped() throws {
    let link = PublishedLink(
        remoteID: 8,
        url: URL(string: "https://links.example/d/token?a=1&b=2")!,
        filename: "design ] review.pdf",
        byteSize: 42,
        expiresAt: Date(timeIntervalSince1970: 2_000_000_000),
        createdAt: Date(timeIntervalSince1970: 1_900_000_000)
    )

    #expect(try OutputFormatter.format(link, as: .raw) == "https://links.example/d/token?a=1&b=2")
    #expect(try OutputFormatter.format(link, as: .markdown) == "[design \\] review.pdf](https://links.example/d/token?a=1&b=2)")
    #expect(try OutputFormatter.format(link, as: .html).contains("a=1&amp;b=2"))
    #expect(try OutputFormatter.format(link, as: .json).contains("\"remoteID\":8"))
}
