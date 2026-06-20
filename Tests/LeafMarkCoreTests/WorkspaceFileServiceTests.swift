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
        XCTAssertEqual(tree.children.map(\.name), ["Child", "notes.txt", "root.md"])
        XCTAssertEqual(tree.children.first?.children.map(\.name), ["child.markdown"])
    }

    func testScanDirectorySortsFoldersBeforeFilesAlphabetically() throws {
        let root = try makeWorkspace()
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Zoo"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Apple"), withIntermediateDirectories: true)
        try write("# B", to: root.appendingPathComponent("b.md"))
        try write("# A", to: root.appendingPathComponent("a.md"))

        let tree = try WorkspaceFileService().scanDirectory(root: root)

        XCTAssertEqual(tree.children.map(\.name), ["Apple", "Zoo", "a.md", "b.md"])
    }

    func testScanDirectorySkipsHiddenAndBuildFolders() throws {
        let root = try makeWorkspace()
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".build"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("build"), withIntermediateDirectories: true)
        try write("# Visible", to: root.appendingPathComponent("visible.md"))
        try write("# Hidden", to: root.appendingPathComponent(".hidden.md"))

        let tree = try WorkspaceFileService().scanDirectory(root: root)

        XCTAssertEqual(tree.children.map(\.name), ["visible.md"])
    }

    func testCreateMarkdownFileAddsDefaultExtension() throws {
        let root = try makeWorkspace()
        let service = WorkspaceFileService()

        let url = try service.createMarkdownFile(named: "notes", in: root)

        XCTAssertEqual(url.lastPathComponent, "notes.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testCreateFolderCreatesDirectory() throws {
        let root = try makeWorkspace()
        let service = WorkspaceFileService()

        let url = try service.createFolder(named: "Drafts", in: root)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testCreateRejectsConflicts() throws {
        let root = try makeWorkspace()
        let service = WorkspaceFileService()
        _ = try service.createMarkdownFile(named: "notes", in: root)

        XCTAssertThrowsError(try service.createMarkdownFile(named: "notes.md", in: root)) { error in
            XCTAssertEqual(error as? WorkspaceFileService.WorkspaceError, .itemAlreadyExists("notes.md"))
        }
    }

    func testRenameFileAndFolder() throws {
        let root = try makeWorkspace()
        let service = WorkspaceFileService()
        let file = try service.createMarkdownFile(named: "old", in: root)
        let folder = try service.createFolder(named: "OldFolder", in: root)

        let renamedFile = try service.renameItem(at: file, to: "new.md")
        let renamedFolder = try service.renameItem(at: folder, to: "NewFolder")

        XCTAssertEqual(renamedFile.lastPathComponent, "new.md")
        XCTAssertEqual(renamedFolder.lastPathComponent, "NewFolder")
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamedFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamedFolder.path))
    }

    func testRenameRejectsConflicts() throws {
        let root = try makeWorkspace()
        let service = WorkspaceFileService()
        let first = try service.createMarkdownFile(named: "first", in: root)
        _ = try service.createMarkdownFile(named: "second", in: root)

        XCTAssertThrowsError(try service.renameItem(at: first, to: "second.md")) { error in
            XCTAssertEqual(error as? WorkspaceFileService.WorkspaceError, .itemAlreadyExists("second.md"))
        }
    }

    func testTrashUsesInjectedHandler() throws {
        let root = try makeWorkspace()
        var trashedURL: URL?
        let service = WorkspaceFileService(trashHandler: { url in
            trashedURL = url
        })
        let file = try service.createMarkdownFile(named: "trash-me", in: root)

        try service.trashItem(at: file)

        XCTAssertEqual(trashedURL, file)
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
