import XCTest
@testable import LeafMarkCore

final class DocumentFileServiceTests: XCTestCase {
    func testSupportedMarkdownExtensions() {
        XCTAssertTrue(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.md")))
        XCTAssertTrue(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.MD")))
        XCTAssertTrue(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.markdown")))
        XCTAssertTrue(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.txt")))
        XCTAssertFalse(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.pdf")))
    }

    func testReadAndWriteUTF8Markdown() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("notes.md")

        let service = DocumentFileService()
        try service.write("# Hello", to: url)

        XCTAssertEqual(try service.read(from: url), "# Hello")
    }

    func testReadRejectsUnsupportedExtension() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("notes.pdf")
        try "# Hello".write(to: url, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try DocumentFileService().read(from: url)) { error in
            XCTAssertEqual(error as? DocumentFileService.FileError, .unsupportedExtension("pdf"))
        }
    }

    func testWriteRejectsUnsupportedExtension() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("notes.pdf")

        XCTAssertThrowsError(try DocumentFileService().write("# Hello", to: url)) { error in
            XCTAssertEqual(error as? DocumentFileService.FileError, .unsupportedExtension("pdf"))
        }
    }

    func testReadRejectsNonUTF8Text() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("notes.md")
        try Data([0xFF, 0xFE]).write(to: url)

        XCTAssertThrowsError(try DocumentFileService().read(from: url)) { error in
            XCTAssertEqual(error as? DocumentFileService.FileError, .unreadableTextEncoding)
        }
    }
}
