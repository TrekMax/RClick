import AppKit

/// File URLs are shared with Finder; move intent belongs only to this clipboard generation.
@MainActor
final class FileClipboard {
    struct CutSession: Codable, Equatable {
        let paths: [String]
        let token: String
        let changeCount: Int
    }

    private static let cutType = NSPasteboard.PasteboardType("cn.wflixu.RClick.cut-session")
    private let pasteboard: NSPasteboard
    private let store: UserDefaults

    init(pasteboard: NSPasteboard, store: UserDefaults) {
        self.pasteboard = pasteboard
        self.store = store
        // Old queues were unrelated to the system clipboard and cannot safely be resumed.
        store.removeObject(forKey: Key.cutFilePaths)
    }

    func writeCut(paths: [String]) -> Bool {
        guard !paths.isEmpty else { return false }
        let urls = paths.map { NSURL(fileURLWithPath: $0) }
        let token = UUID().uuidString
        pasteboard.clearContents()
        store.removeObject(forKey: Key.cutClipboardSession)
        guard pasteboard.writeObjects(urls), pasteboard.setString(token, forType: Self.cutType) else {
            return false
        }
        let cut = CutSession(paths: paths, token: token, changeCount: pasteboard.changeCount)
        guard let data = try? JSONEncoder().encode(cut) else { return false }
        store.set(data, forKey: Key.cutClipboardSession)
        return true
    }

    func pendingCut() -> CutSession? {
        guard let data = store.data(forKey: Key.cutClipboardSession),
              let cut = try? JSONDecoder().decode(CutSession.self, from: data),
              pasteboard.changeCount == cut.changeCount,
              pasteboard.string(forType: Self.cutType) == cut.token,
              fileURLs().map(\.path) == cut.paths,
              pasteboard.changeCount == cut.changeCount else {
            store.removeObject(forKey: Key.cutClipboardSession)
            return nil
        }
        return cut
    }

    func fileURLs() -> [URL] {
        let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) ?? []
        return objects.compactMap { $0 as? URL }
    }

    func finishMove(_ cut: CutSession, failedPaths: [String]) {
        // Permission prompts can allow another copy/cut while an operation is in progress.
        guard pendingCut() == cut else { return }
        if failedPaths.isEmpty {
            store.removeObject(forKey: Key.cutClipboardSession)
            pasteboard.clearContents()
        } else {
            _ = writeCut(paths: failedPaths)
        }
    }
}
