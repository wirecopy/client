import AppKit
import Foundation
import UniformTypeIdentifiers

public enum InputInspector {
    public static func prepareClipboard() throws -> PreparedAsset {
        let pasteboard = NSPasteboard.general
        let fileOptions: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: fileOptions) as? [URL], !urls.isEmpty {
            return try prepare(urls: urls)
        }

        // Some apps provide a file URL without an NSURL-readable pasteboard item.
        if let value = pasteboard.string(forType: .fileURL),
           let url = URL(string: value), url.isFileURL {
            return try prepare(urls: [url])
        }
        let legacyFilenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if let paths = pasteboard.propertyList(forType: legacyFilenamesType) as? [String], !paths.isEmpty {
            return try prepare(urls: paths.map { URL(fileURLWithPath: $0) })
        }

        let imageTypes: [(NSPasteboard.PasteboardType, String, String)] = [
            (.init("public.png"), "png", "image/png"),
            (.init("public.jpeg"), "jpg", "image/jpeg"),
            (.tiff, "png", "image/png")
        ]
        for (type, ext, mime) in imageTypes {
            guard let data = pasteboard.data(forType: type) else { continue }
            let outputData: Data
            if type == .tiff {
                guard let image = NSImage(data: data),
                      let tiff = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiff),
                      let png = bitmap.representation(using: .png, properties: [:]) else {
                    throw WirecopyError.noSupportedClipboardContent
                }
                outputData = png
            } else {
                outputData = data
            }
            let filename = "clipboard-\(timestamp()).\(ext)"
            let url = temporaryDirectory().appending(path: filename)
            try outputData.write(to: url, options: .atomic)
            return PreparedAsset(fileURL: url, filename: filename, contentType: mime, byteSize: Int64(outputData.count), removeAfterUse: true)
        }

        throw WirecopyError.noSupportedClipboardContent
    }

    public static func prepare(urls: [URL]) throws -> PreparedAsset {
        guard !urls.isEmpty else { throw WirecopyError.noSupportedClipboardContent }
        for url in urls {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                throw WirecopyError.unsupportedDirectory(url)
            }
        }
        if urls.count == 1 { return try prepareFile(urls[0]) }

        let output = temporaryDirectory().appending(path: "wirecopy-files-\(timestamp()).zip")
        try DeterministicZip.create(from: urls, at: output)
        let size = try fileSize(output)
        return PreparedAsset(fileURL: output, filename: output.lastPathComponent, contentType: "application/zip", byteSize: size, removeAfterUse: true)
    }

    private static func prepareFile(_ url: URL) throws -> PreparedAsset {
        let size = try fileSize(url)
        let type = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)?.preferredMIMEType ?? "application/octet-stream"
        return PreparedAsset(fileURL: url, filename: safeFilename(url.lastPathComponent), contentType: type, byteSize: size)
    }

    private static func fileSize(_ url: URL) throws -> Int64 {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else { throw WirecopyError.unreadableFile(url) }
        return Int64(size)
    }

    private static func temporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: "wirecopy", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
    }

    private static func safeFilename(_ value: String) -> String {
        value.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "\0", with: "_")
    }
}
