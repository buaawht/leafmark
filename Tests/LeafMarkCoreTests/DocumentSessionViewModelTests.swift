import XCTest
@testable import LeafMarkCore

@MainActor
final class DocumentSessionViewModelTests: XCTestCase {
    func testSessionStartsWithWelcomeTab() {
        let session = DocumentSessionViewModel()

        XCTAssertEqual(session.tabs.count, 1)
        XCTAssertEqual(session.selectedTab?.markdownText, WelcomeDocument.text)
        XCTAssertEqual(session.selectedTab?.displayName, "Welcome")
        XCTAssertFalse(session.selectedTab?.hasUnsavedChanges ?? true)
    }

    func testEditingSelectedTabMarksOnlyThatTabDirty() {
        let session = DocumentSessionViewModel()
        let cleanID = session.selectedTabID
        session.newTab()
        let dirtyID = session.selectedTabID

        session.selectedTab?.markdownText = "# Dirty"

        XCTAssertEqual(session.tab(id: cleanID)?.hasUnsavedChanges, false)
        XCTAssertEqual(session.tab(id: dirtyID)?.hasUnsavedChanges, true)
    }

    func testNewTabCreatesBlankUntitledDocument() {
        let session = DocumentSessionViewModel()

        session.newTab()

        XCTAssertEqual(session.selectedTab?.markdownText, "")
        XCTAssertEqual(session.selectedTab?.displayName, "Untitled.md")
        XCTAssertFalse(session.selectedTab?.hasUnsavedChanges ?? true)
    }

    func testOpeningSameFileTwiceSelectsExistingTab() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("notes.md")
        try "# Notes".write(to: url, atomically: true, encoding: .utf8)

        let session = DocumentSessionViewModel()
        try session.openTab(url: url)
        let openedID = session.selectedTabID
        try session.openTab(url: url)

        XCTAssertEqual(session.tabs.count, 2)
        XCTAssertEqual(session.selectedTabID, openedID)
    }

    func testClosingCleanTabRemovesIt() {
        let session = DocumentSessionViewModel()
        session.newTab()
        let tabToClose = session.selectedTabID

        XCTAssertTrue(session.closeTab(id: tabToClose))

        XCTAssertEqual(session.tabs.count, 1)
        XCTAssertNotEqual(session.selectedTabID, tabToClose)
    }

    func testCloseOthersKeepsSelectedTab() {
        let session = DocumentSessionViewModel()
        let firstID = session.selectedTabID
        session.newTab()
        session.newTab()

        session.selectedTabID = firstID
        let closed = session.closeOtherTabs(keeping: firstID)

        XCTAssertEqual(closed, 2)
        XCTAssertEqual(session.tabs.map(\.id), [firstID])
        XCTAssertEqual(session.selectedTabID, firstID)
    }

    func testMoveTabReordersTabs() {
        let session = DocumentSessionViewModel()
        let firstID = session.selectedTabID
        session.newTab()
        let secondID = session.selectedTabID
        session.newTab()
        let thirdID = session.selectedTabID

        session.moveTab(id: thirdID, before: firstID)

        XCTAssertEqual(session.tabs.map(\.id), [thirdID, firstID, secondID])
    }

    func testSaveAsUpdatesSelectedTabURLTitleAndBaseline() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("saved.md")
        let session = DocumentSessionViewModel()
        session.selectedTab?.markdownText = "# Saved"

        try session.saveSelectedAs(url: url)

        XCTAssertEqual(session.selectedTab?.fileURL, url)
        XCTAssertEqual(session.selectedTab?.displayName, "saved.md")
        XCTAssertEqual(session.selectedTab?.baselineText, "# Saved")
        XCTAssertFalse(session.selectedTab?.hasUnsavedChanges ?? true)
    }
}
