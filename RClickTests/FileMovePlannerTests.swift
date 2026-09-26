import Foundation
import Testing
@testable import RClick

@MainActor
struct FileMovePlannerTests {
    @Test func destinationAndConflictingNames() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("rclick-planner-\(UUID())")
        defer { try? fm.removeItem(at: root) }
        let directory = root.appendingPathComponent("Literal%20Folder", isDirectory: true)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("Report.pdf")
        try Data().write(to: file)
        try Data().write(to: directory.appendingPathComponent("Report 1.pdf"))

        #expect(FileMovePlanner.destinationDirectory(from: [directory.path]) == directory)
        #expect(FileMovePlanner.destinationDirectory(from: [file.path]) == directory)
        #expect(FileMovePlanner.destinationDirectory(from: []) == nil)
        #expect(FileMovePlanner.destinationDirectory(from: [root.appendingPathComponent("Missing").path]) == nil)
        #expect(FileMovePlanner.availableDestination(for: file, in: directory).lastPathComponent == "Report 2.pdf")
    }
}
