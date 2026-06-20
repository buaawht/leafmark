import XCTest
@testable import LeafMarkCore

@MainActor
final class DocumentViewModelTests: XCTestCase {
    func testStartsWithWelcomeDocumentAndNoFileURL() {
        let model = DocumentViewModel()

        XCTAssertEqual(model.markdownText, WelcomeDocument.text)
        XCTAssertNil(model.fileURL)
        XCTAssertEqual(model.displayName, "Welcome")
        XCTAssertFalse(model.hasUnsavedChanges)
    }

    func testEditingMarksDocumentDirty() {
        let model = DocumentViewModel()

        model.markdownText = "# Changed"

        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertEqual(model.saveStatusText, "Unsaved")
    }

    func testLoadingFileResetsBaseline() {
        let model = DocumentViewModel()
        let url = URL(fileURLWithPath: "/tmp/notes.md")

        model.load(text: "# Notes", from: url)

        XCTAssertEqual(model.markdownText, "# Notes")
        XCTAssertEqual(model.baselineText, "# Notes")
        XCTAssertEqual(model.fileURL, url)
        XCTAssertEqual(model.displayName, "notes.md")
        XCTAssertFalse(model.hasUnsavedChanges)
    }

    func testWordAndCharacterCounts() {
        let model = DocumentViewModel()

        model.markdownText = "Hello LeafMark\n\n你好"

        XCTAssertEqual(model.wordCount, 2)
        XCTAssertEqual(model.characterCount, 18)
    }

    func testPathSummaryUsesTildeForHomeDirectory() {
        let model = DocumentViewModel()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("Documents/notes.md")

        model.load(text: "# Notes", from: url)

        XCTAssertEqual(model.pathSummary, "~/Documents/notes.md")
    }

    func testWindowTitleMarksDirtyDocuments() {
        let model = DocumentViewModel()

        XCTAssertEqual(model.windowTitle, "Welcome — LeafMark")

        model.markdownText = "# Dirty"

        XCTAssertEqual(model.windowTitle, "• Welcome — LeafMark")
    }
}
