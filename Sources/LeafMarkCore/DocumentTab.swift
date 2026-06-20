import Foundation
import Observation

@MainActor
@Observable
public final class DocumentTab: Identifiable, Equatable {
    public let id: UUID
    public var markdownText: String {
        didSet {
            hasUnsavedChanges = markdownText != baselineText
        }
    }

    public private(set) var baselineText: String
    public private(set) var fileURL: URL?
    public var renderedHTML: String
    public private(set) var hasUnsavedChanges: Bool
    public private(set) var isWelcomeDocument: Bool

    public init(
        id: UUID = UUID(),
        markdownText: String = "",
        fileURL: URL? = nil,
        renderedHTML: String = "",
        isWelcomeDocument: Bool = false
    ) {
        self.id = id
        self.markdownText = markdownText
        self.baselineText = markdownText
        self.fileURL = fileURL
        self.renderedHTML = renderedHTML
        self.hasUnsavedChanges = false
        self.isWelcomeDocument = isWelcomeDocument
    }

    public nonisolated static func == (lhs: DocumentTab, rhs: DocumentTab) -> Bool {
        lhs.id == rhs.id
    }

    public var displayName: String {
        fileURL?.lastPathComponent ?? (isWelcomeDocument ? "Welcome" : "Untitled.md")
    }

    public var windowTitleFragment: String {
        let dirtyPrefix = hasUnsavedChanges ? "• " : ""
        return "\(dirtyPrefix)\(displayName)"
    }

    public var saveStatusText: String {
        hasUnsavedChanges ? "Unsaved" : "Saved"
    }

    public var wordCount: Int {
        markdownText
            .split { $0.isWhitespace || $0.isNewline }
            .filter { token in
                token.contains { character in
                    character.unicodeScalars.contains { scalar in
                        (48...57).contains(scalar.value)
                            || (65...90).contains(scalar.value)
                            || (97...122).contains(scalar.value)
                    }
                }
            }
            .count
    }

    public var characterCount: Int {
        markdownText.count
    }

    public var pathSummary: String {
        guard let fileURL else { return "No file" }
        let path = fileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    public var baseFileURLForPreview: URL? {
        fileURL
    }

    public func load(text: String, from url: URL) {
        markdownText = text
        baselineText = text
        fileURL = url
        hasUnsavedChanges = false
        isWelcomeDocument = false
    }

    public func markSaved(to url: URL) {
        baselineText = markdownText
        fileURL = url
        hasUnsavedChanges = false
        isWelcomeDocument = false
    }

    public func updateFileURL(_ url: URL) {
        fileURL = url
        isWelcomeDocument = false
    }
}
