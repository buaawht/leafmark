import XCTest
@testable import LeafMarkCore

final class ExportServiceTests: XCTestCase {
    func testExportMarkdownWritesUTF8File() throws {
        let service = ExportService()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }

        try service.exportMarkdown("# 标题\n\nHello LeafMark", to: url)

        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "# 标题\n\nHello LeafMark")
    }

    func testExportNamesUseCurrentDocumentBaseName() {
        let service = ExportService()

        XCTAssertEqual(service.markdownExportName(for: "Notes.markdown"), "Notes.md")
        XCTAssertEqual(service.pdfExportName(for: "Notes.markdown"), "Notes.pdf")
        XCTAssertEqual(service.markdownExportName(for: ""), "Untitled.md")
        XCTAssertEqual(service.pdfExportName(for: ""), "Untitled.pdf")
    }
}
