import Foundation
import Observation

@MainActor
@Observable
public final class DocumentViewModel {
    public var markdownText: String {
        didSet {
            hasUnsavedChanges = markdownText != baselineText
        }
    }

    public private(set) var baselineText: String
    public private(set) var fileURL: URL?
    public var errorMessage: String?
    public private(set) var hasUnsavedChanges: Bool

    public init() {
        self.markdownText = WelcomeDocument.text
        self.baselineText = WelcomeDocument.text
        self.fileURL = nil
        self.hasUnsavedChanges = false
    }

    public var displayName: String {
        fileURL?.lastPathComponent ?? "Welcome"
    }

    public var windowTitle: String {
        let dirtyPrefix = hasUnsavedChanges ? "• " : ""
        return "\(dirtyPrefix)\(displayName) — LeafMark"
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

    public func newWelcomeDocument() {
        markdownText = WelcomeDocument.text
        baselineText = WelcomeDocument.text
        fileURL = nil
        hasUnsavedChanges = false
    }

    public func load(text: String, from url: URL) {
        markdownText = text
        baselineText = text
        fileURL = url
        hasUnsavedChanges = false
    }

    public func open(url: URL, fileService: DocumentFileService = DocumentFileService()) throws {
        let text = try fileService.read(from: url)
        load(text: text, from: url)
    }

    public func save(fileService: DocumentFileService = DocumentFileService()) throws -> Bool {
        guard let fileURL else { return false }
        try fileService.write(markdownText, to: fileURL)
        markSaved(to: fileURL)
        return true
    }

    public func saveAs(url: URL, fileService: DocumentFileService = DocumentFileService()) throws {
        try fileService.write(markdownText, to: url)
        markSaved(to: url)
    }

    public func markSaved(to url: URL) {
        baselineText = markdownText
        fileURL = url
        hasUnsavedChanges = false
    }
}
