import Foundation

public enum OutputFormat: String, CaseIterable, Sendable {
    case raw
    case markdown
    case html
    case json
}

public enum OutputFormatter {
    public static func format(_ link: PublishedLink, as format: OutputFormat) throws -> String {
        switch format {
        case .raw:
            link.url.absoluteString
        case .markdown:
            "[\(escapeMarkdown(link.filename))](\(link.url.absoluteString))"
        case .html:
            #"<a href="\#(escapeHTML(link.url.absoluteString))">\#(escapeHTML(link.filename))</a>"#
        case .json:
            try String(decoding: JSONEncoder.wirecopy.encode(link), as: UTF8.self)
        }
    }

    private static func escapeMarkdown(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "]", with: "\\]")
    }

    private static func escapeHTML(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

private extension JSONEncoder {
    static var wirecopy: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
