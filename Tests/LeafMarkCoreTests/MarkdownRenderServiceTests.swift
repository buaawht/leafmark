import XCTest
@testable import LeafMarkCore

final class MarkdownRenderServiceTests: XCTestCase {
    func testRenderReturnsCompleteHTMLDocumentWithCommonMarkdown() throws {
        let markdown = """
        # Title

        A paragraph with **bold** text and [a link](https://example.com).

        > A quote

        - One
        - Two

        | Animal | Sound |
        | --- | --- |
        | Cat | Meow |

        ![Cat](images/cat.png)

        <script>alert("xss")</script>
        """

        let html = try MarkdownRenderService().render(
            markdown,
            baseFileURL: URL(fileURLWithPath: "/tmp/LeafMark/notes.md")
        )

        XCTAssertTrue(html.contains("<!doctype html>"))
        XCTAssertTrue(html.contains("<h1"))
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("https://example.com"))
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("file:///tmp/LeafMark/images/cat.png"))
        XCTAssertFalse(html.contains("<script>alert"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testRenderEmphasisStrongAndCodeEscaping() throws {
        let markdown = """
        A paragraph with *emphasis*, **strong**, and `<tag>`.

        ```html
        <script>alert("x")</script>
        ```
        """

        let html = try MarkdownRenderService().render(markdown, baseFileURL: nil)

        XCTAssertTrue(html.contains("<em>emphasis</em>"))
        XCTAssertTrue(html.contains("<strong>strong</strong>"))
        XCTAssertTrue(html.contains("<code>&lt;tag&gt;</code>"))
        XCTAssertTrue(html.contains("<pre><code class=\"language-html\">&lt;script&gt;alert(\"x\")&lt;/script&gt;"))
    }

    func testRenderOrderedList() throws {
        let markdown = """
        1. One
        2. Two
        """

        let html = try MarkdownRenderService().render(markdown, baseFileURL: nil)

        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("<li>"))
        XCTAssertTrue(html.contains("One"))
        XCTAssertTrue(html.contains("Two"))
    }

    func testRenderTableHeaderAndBodyCells() throws {
        let markdown = """
        | Name | Value |
        | --- | --- |
        | Leaf | Mark |
        """

        let html = try MarkdownRenderService().render(markdown, baseFileURL: nil)

        XCTAssertTrue(html.contains("<thead>"))
        XCTAssertTrue(html.contains("<th>Name</th>"))
        XCTAssertTrue(html.contains("<th>Value</th>"))
        XCTAssertTrue(html.contains("<tbody>"))
        XCTAssertTrue(html.contains("<td>Leaf</td>"))
        XCTAssertTrue(html.contains("<td>Mark</td>"))
    }

    func testRenderPreservesSafeExternalLink() throws {
        let html = try MarkdownRenderService().render(
            "[Example](https://example.com)",
            baseFileURL: nil
        )

        XCTAssertTrue(html.contains("href=\"https://example.com\""))
    }

    func testRenderOmitsUnsafeLinkHref() throws {
        let html = try MarkdownRenderService().render(
            "[Bad](javascript:alert(1))",
            baseFileURL: nil
        )

        XCTAssertFalse(html.contains("href=\"javascript:"))
        XCTAssertFalse(html.contains("javascript:alert"))
        XCTAssertTrue(html.contains("Bad"))
    }

    func testRenderOmitsWhitespacePrefixedUnsafeLinkHref() throws {
        let markdown = """
        [Space](< javascript:alert(1)>)

        [Newline](
        javascript:alert(1))
        """

        let html = try MarkdownRenderService().render(markdown, baseFileURL: nil)

        XCTAssertFalse(html.contains("href=\" javascript:"))
        XCTAssertFalse(html.contains("href=\"javascript:"))
        XCTAssertFalse(html.contains("javascript:alert"))
        XCTAssertTrue(html.contains("Space"))
        XCTAssertTrue(html.contains("Newline"))
    }

    func testRenderOmitsUnsafeImageSource() throws {
        let html = try MarkdownRenderService().render(
            "![Bad](data:image/png;base64,abc)",
            baseFileURL: nil
        )

        XCTAssertFalse(html.contains("src=\"data:"))
        XCTAssertFalse(html.contains("data:image"))
        XCTAssertTrue(html.contains("<img"))
    }

    func testRenderOmitsControlPrefixedUnsafeImageSource() throws {
        let html = try MarkdownRenderService().render(
            "![Bad](<\tdata:text/html,abc>)",
            baseFileURL: nil
        )

        XCTAssertFalse(html.contains("src=\"\tdata:"))
        XCTAssertFalse(html.contains("src=\"data:"))
        XCTAssertFalse(html.contains("data:text/html"))
        XCTAssertTrue(html.contains("<img"))
    }

    func testRenderEscapesImageAltAttribute() throws {
        let html = try MarkdownRenderService().render(
            "![A \"Cat\"](images/cat.png)",
            baseFileURL: URL(fileURLWithPath: "/tmp/LeafMark/notes.md")
        )

        XCTAssertTrue(html.contains("alt=\"A &quot;Cat&quot;\""))
    }
}
