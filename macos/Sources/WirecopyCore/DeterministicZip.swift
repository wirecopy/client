import Foundation

public enum DeterministicZip {
    private struct Entry {
        let name: Data
        let bytes: Data
        let crc: UInt32
        let offset: UInt32
    }

    public static func create(from urls: [URL], at destination: URL) throws {
        var usedNames: Set<String> = []
        let sources = urls.sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }).map { url in
            (url, uniqueName(url.lastPathComponent, used: &usedNames))
        }
        try create(from: sources, at: destination)
    }

    public static func createSite(from directory: URL, at destination: URL) throws {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey]
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { throw WirecopyError.invalidSite("Wirecopy could not read this site folder.") }

        var sources: [(URL, String)] = []
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: Set(keys))
            if values.isSymbolicLink == true { throw WirecopyError.invalidSite("Site folders cannot contain symbolic links.") }
            guard values.isRegularFile == true else { continue }
            let prefix = directory.standardizedFileURL.path + "/"
            let path = url.standardizedFileURL.path.replacingOccurrences(of: prefix, with: "", options: .anchored)
            guard !path.isEmpty, !path.split(separator: "/").contains("..") else {
                throw WirecopyError.invalidSite("The site folder contains an unsafe path.")
            }
            sources.append((url, path))
        }
        guard sources.contains(where: { $0.1 == "index.html" }) else {
            throw WirecopyError.invalidSite("The site folder needs an index.html file at its root.")
        }
        try create(from: sources.sorted(by: { $0.1 < $1.1 }), at: destination)
    }

    private static func create(from sources: [(URL, String)], at destination: URL) throws {
        var archive = Data()
        var entries: [Entry] = []

        for (url, filename) in sources {
            let bytes = try Data(contentsOf: url, options: .mappedIfSafe)
            let name = Data(filename.utf8)
            let offset = UInt32(archive.count)
            let crc = crc32(bytes)

            archive.appendLE(UInt32(0x04034b50))
            archive.appendLE(UInt16(20))
            archive.appendLE(UInt16(0x0800))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0x0021))
            archive.appendLE(crc)
            archive.appendLE(UInt32(bytes.count))
            archive.appendLE(UInt32(bytes.count))
            archive.appendLE(UInt16(name.count))
            archive.appendLE(UInt16(0))
            archive.append(name)
            archive.append(bytes)
            entries.append(.init(name: name, bytes: bytes, crc: crc, offset: offset))
        }

        let centralOffset = UInt32(archive.count)
        for entry in entries {
            archive.appendLE(UInt32(0x02014b50))
            archive.appendLE(UInt16(0x0314))
            archive.appendLE(UInt16(20))
            archive.appendLE(UInt16(0x0800))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0x0021))
            archive.appendLE(entry.crc)
            archive.appendLE(UInt32(entry.bytes.count))
            archive.appendLE(UInt32(entry.bytes.count))
            archive.appendLE(UInt16(entry.name.count))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt32(0x81A40000))
            archive.appendLE(entry.offset)
            archive.append(entry.name)
        }
        let centralSize = UInt32(archive.count) - centralOffset
        archive.appendLE(UInt32(0x06054b50))
        archive.appendLE(UInt16(0))
        archive.appendLE(UInt16(0))
        archive.appendLE(UInt16(entries.count))
        archive.appendLE(UInt16(entries.count))
        archive.appendLE(centralSize)
        archive.appendLE(centralOffset)
        archive.appendLE(UInt16(0))
        try archive.write(to: destination, options: .atomic)
    }

    private static func uniqueName(_ input: String, used: inout Set<String>) -> String {
        let clean = input.replacingOccurrences(of: "/", with: "_")
        if used.insert(clean).inserted { return clean }
        let stem = (clean as NSString).deletingPathExtension
        let ext = (clean as NSString).pathExtension
        var index = 2
        while true {
            let candidate = ext.isEmpty ? "\(stem)-\(index)" : "\(stem)-\(index).\(ext)"
            if used.insert(candidate).inserted { return candidate }
            index += 1
        }
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = (crc >> 1) ^ (0xEDB88320 & (0 &- (crc & 1))) }
        }
        return ~crc
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { append(contentsOf: $0) }
    }
}
