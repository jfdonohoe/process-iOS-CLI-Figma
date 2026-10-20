import Foundation

enum GPXLibrary {
    static var folder: URL {
        URL.documentsDirectory.appending(path: "GPX", directoryHint: .isDirectory)
    }

    /// Newest import first.
    static func files() throws -> [URL] {
        let urls = try FileManager.default.contentsOfDirectory(at: folder,
                                                               includingPropertiesForKeys: [.contentModificationDateKey])
        return urls
            .filter { $0.pathExtension == "gpx" }
            .sorted { modified($0) > modified($1) }
    }

    private static func modified(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
}
