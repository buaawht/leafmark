import XCTest
@testable import LeafMarkCore

final class DocumentOutlineServiceTests: XCTestCase {
    func testParsesHeadingLevelsAndLines() {
        let outline = DocumentOutlineService().parse("""
        # Title

        ## Section

        ###### Deep
        """)

        XCTAssertEqual(outline.map(\\.title), ["Title", "Section", "Deep"])
        XCTAssertEqual(outline.map(\\.level), [1, 2, 6])
        XCTAssertEqual(outline.map(\\.line), [1, 3, 5])
        XCTAssertEqual(outline.map(\\.slug), ["title", "section", "deep"])
    }

    func testIgnoresHeadingsInsideFencedCodeBlocks() {
        let outline = DocumentOutlineService().parse("""
        # Real

        ```markdown
        # Not Real
        ```

        ## Also Real
        """)

        XCTAssertEqual(outline.map(\\.title), ["Real", "Also Real"])
    }

    func testCreatesUniqueSlugsForDuplicateHeadings() {
        let outline = DocumentOutlineService().parse("""
        # Intro
        ## Intro
        ## Intro!
        """)

        XCTAssertEqual(outline.map(\\.slug), ["intro", "intro-1", "intro-2"])
    }

    func testReturnsEmptyOutlineWhenNoHeadingsExist() {
        let outline = DocumentOutlineService().parse("Just a paragraph.")

        XCTAssertTrue(outline.isEmpty)
    }
}
