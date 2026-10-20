import Foundation

enum GPXLibrary {
    static var folder: URL {
        URL.documentsDirectory.appending(path: "GPX", directoryHint: .isDirectory)
    }

    static func files() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "gpx" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
