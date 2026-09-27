import AppKit
import Testing
@testable import RClick

@MainActor
struct FileClipboardTests {
    private func withClipboard(_ body: (FileClipboard, NSPasteboard, UserDefaults) throws -> Void) throws {
        let name = "rclick-clipboard-\(UUID())"
        let store = try #require(UserDefaults(suiteName: name))
        let board = NSPasteboard.withUniqueName()
        defer {
            board.releaseGlobally()
            store.removePersistentDomain(forName: name)
        }
        try body(FileClipboard(pasteboard: board, store: store), board, store)
    }

    @Test func cutReplacesTextWithStandardFileURLsAndSurvivesServiceRestart() throws {
        try withClipboard { clipboard, board, store in
            board.setString("previous text", forType: .string)
            let paths = ["/tmp/A space.txt", "/tmp/字面%20文件.txt"]
            #expect(clipboard.writeCut(paths: paths))
            let files = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
            #expect(files?.map(\.path) == paths)
            #expect(board.string(forType: .string) != "previous text")
            #expect(FileClipboard(pasteboard: board, store: store).pendingCut()?.paths == paths)
        }
    }

    @Test func copyingTheSameFilesAgainChangesCutIntoCopy() throws {
        try withClipboard { clipboard, board, _ in
            #expect(clipboard.writeCut(paths: ["/tmp/A.txt"]))
            board.clearContents()
            #expect(board.writeObjects([NSURL(fileURLWithPath: "/tmp/A.txt")]))
            #expect(clipboard.pendingCut() == nil)
            #expect(clipboard.fileURLs().map(\.path) == ["/tmp/A.txt"])
        }
    }

    @Test func restoringClipboardItemsDoesNotRestoreOldCutIntent() throws {
        try withClipboard { clipboard, board, _ in
            #expect(clipboard.writeCut(paths: ["/tmp/A.txt"]))
            let items = try #require(board.pasteboardItems).map { old in
                let item = NSPasteboardItem()
                for type in old.types {
                    if let data = old.data(forType: type) { item.setData(data, forType: type) }
                }
                return item
            }
            board.clearContents()
            #expect(board.writeObjects(items))
            #expect(clipboard.pendingCut() == nil)
        }
    }

    @Test func successfulMoveClearsOnlyItsOwnClipboard() throws {
        try withClipboard { clipboard, board, _ in
            #expect(clipboard.writeCut(paths: ["/tmp/A.txt"]))
            let cut = try #require(clipboard.pendingCut())
            clipboard.finishMove(cut, failedPaths: [])
            #expect(clipboard.pendingCut() == nil)
            #expect(clipboard.fileURLs().isEmpty)
            #expect(board.pasteboardItems?.isEmpty != false)
        }
    }

    @Test func partialMoveLeavesOnlyFailedItemsForRetry() throws {
        try withClipboard { clipboard, _, _ in
            #expect(clipboard.writeCut(paths: ["/tmp/A.txt", "/tmp/B.txt"]))
            let cut = try #require(clipboard.pendingCut())
            clipboard.finishMove(cut, failedPaths: ["/tmp/B.txt"])
            #expect(clipboard.pendingCut()?.paths == ["/tmp/B.txt"])
            #expect(clipboard.fileURLs().map(\.path) == ["/tmp/B.txt"])
        }
    }

    @Test(arguments: [[], ["/tmp/A.txt"]])
    func completionPreservesNewExternalClipboard(failedPaths: [String]) throws {
        try withClipboard { clipboard, board, _ in
            #expect(clipboard.writeCut(paths: ["/tmp/A.txt"]))
            let cut = try #require(clipboard.pendingCut())
            board.clearContents()
            board.setString("new text", forType: .string)
            clipboard.finishMove(cut, failedPaths: failedPaths)
            #expect(board.string(forType: .string) == "new text")
            #expect(clipboard.pendingCut() == nil)
        }
    }

    @Test func completionDoesNotClearANewerCut() throws {
        try withClipboard { clipboard, _, _ in
            #expect(clipboard.writeCut(paths: ["/tmp/A.txt"]))
            let old = try #require(clipboard.pendingCut())
            #expect(clipboard.writeCut(paths: ["/tmp/B.txt"]))
            clipboard.finishMove(old, failedPaths: [])
            #expect(clipboard.pendingCut()?.paths == ["/tmp/B.txt"])
        }
    }

    @Test func legacyQueueCannotOverrideCurrentFinderCopy() throws {
        try withClipboard { _, board, store in
            store.set(["/tmp/Old.txt"], forKey: Key.cutFilePaths)
            board.clearContents()
            #expect(board.writeObjects([NSURL(fileURLWithPath: "/tmp/New.txt")]))
            let clipboard = FileClipboard(pasteboard: board, store: store)
            #expect(clipboard.pendingCut() == nil)
            #expect(clipboard.fileURLs().map(\.path) == ["/tmp/New.txt"])
            #expect(store.object(forKey: Key.cutFilePaths) == nil)
        }
    }
}
