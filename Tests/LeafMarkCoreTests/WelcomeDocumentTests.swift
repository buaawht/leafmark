import XCTest
@testable import LeafMarkCore

final class WelcomeDocumentTests: XCTestCase {
    func testWelcomeDocumentShowsCoreMarkdownFeatures() {
        let text = WelcomeDocument.text

        XCTAssertTrue(text.contains("# Welcome to LeafMark"))
        XCTAssertTrue(text.contains("| Feature | Status |"))
        XCTAssertTrue(text.contains("![Local image example]"))
        XCTAssertTrue(text.contains("```swift"))
    }
}
