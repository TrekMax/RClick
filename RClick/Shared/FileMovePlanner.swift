import Foundation

struct FileMovePlanner {
    static func destinationDirectory(from targetPaths: [String], fileManager: FileManager = .default) -> URL? {
        guard let rawPath = targetPaths.first else {
            return nil
        }

        // ClickEventPayload carries URL.path, which is already decoded.
        let path = rawPath
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return nil
        }
        if isDirectory.boolValue {
            return URL(fileURLWithPath: path, isDirectory: true)
        }

        return URL(fileURLWithPath: path).deletingLastPathComponent()
    }

    static func availableDestination(for sourceURL: URL, in destinationDirectory: URL, fileManager: FileManager = .default) -> URL {
        let preferredDestination = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        guard fileManager.fileExists(atPath: preferredDestination.path) else {
            return preferredDestination
        }

        let extensionName = sourceURL.pathExtension
        let baseName = extensionName.isEmpty
            ? sourceURL.lastPathComponent
            : sourceURL.deletingPathExtension().lastPathComponent

        var index = 1
        while true {
            let fileName = extensionName.isEmpty ? "\(baseName) \(index)" : "\(baseName) \(index).\(extensionName)"
            let candidate = destinationDirectory.appendingPathComponent(fileName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}
