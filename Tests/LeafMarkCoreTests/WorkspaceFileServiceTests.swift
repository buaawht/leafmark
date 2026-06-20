import XCTest
@testable import LeafMarkCore

final class WorkspaceFileServiceTests: XCTestCase {
    func testScanDirectoryIncludesSupportedDocumentsAndFolders() throws {
        let root = try makeWorkspace()
        try write("# Root", to: root.appendingPathComponent("root.md"))
        try write("# Text", to: root.appendingPathComponent("notes.txt"))
        try write("PDF", to: root.appendingPathComponent("ignored.pdf"))
        let child = root.appendingPathComponent("Child")
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        try write("# Child", to: child.appendingPathComponent("child.markdown"))

        let tree = try WorkspaceFileService().scanDirectory(root: root)

        XCTAssertEqual(tree.name, root.lastPathComponent)
        XCTAssertEqual(tree.kind, .folder)
        XCTAssertEqual(tree.children.map(\\.name), ["Child", "notes.txt", "root.md"])
        XCTAssertEqual(tree.children.first?.children.map(\\.name), ["child.markdown"])
    }

    func testScanDirectorySortsFoldersBeforeFilesAlphabetically() throws {
        let root = try makeWorkspace()
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Zoo"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Apple"), withIntermediateDirectories: true)
        try write("# B", to: root.appendingPathComponent("b.md"))
        try write("# A", to: root.appendingPathComponent("a.md"))

        let tree = try WorkspaceFileService().scanDirectory(root: root)

        XCTAssertEqual(tree.children.map(\\.name), ["Apple", "Zoo", "a.md", "b.md"])
    }

    func testScanDirectorySkipsHiddenAndBuildFolders() throws {
        let root = try makeWorkspace()
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".build"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("build"), withIntermediateDirectories: true)
        try write("# Visible", to: root.appendingPathComponent("visible.md"))
        try write("# Hidden", to: root.appendingPathComponent(".hidden.md"))

        let tree = try WorkspaceFileService().scanDirectory(root: root)

        XCTAssertEqual(tree.children.map(\\.name), ["visible.md"])
    }

    private func makeWorkspace() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }
        return root
    }

    private func write(_ text: String, to url: URL) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
