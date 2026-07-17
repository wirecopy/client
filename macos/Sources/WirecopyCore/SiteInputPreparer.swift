import Foundation

public enum SiteInputPreparer {
    public static func prepare(_ url: URL) throws -> PreparedSite {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
        if values.isDirectory == true {
            let output = temporaryDirectory().appending(path: "wirecopy-site-\(timestamp()).zip")
            try DeterministicZip.createSite(from: url, at: output)
            return PreparedSite(archiveURL: output, removeAfterUse: true)
        }

        guard values.isRegularFile == true else {
            throw WirecopyError.invalidSite("Choose an HTML file, ZIP, or folder containing index.html.")
        }
        guard ["html", "htm", "zip"].contains(url.pathExtension.lowercased()) else {
            throw WirecopyError.invalidSite("Site publishing accepts .html, .htm, or .zip inputs.")
        }
        return PreparedSite(archiveURL: url, removeAfterUse: false)
    }

    private static func temporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: "wirecopy", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
    }
}
