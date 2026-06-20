import Foundation

public struct ExportService {
    public init() {}

    public func exportMarkdown(_ markdown: String, to url: URL) throws {
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }

    public func markdownExportName(for displayName: String) -> String {
        let url = URL(fileURLWithPath: displayName)
        let baseName = url.deletingPathExtension().lastPathComponent
        return baseName.isEmpty ? "Untitled.md" : baseName + ".md"
    }

    public func pdfExportName(for displayName: String) -> String {
        let url = URL(fileURLWithPath: displayName)
        let baseName = url.deletingPathExtension().lastPathComponent
        return baseName.isEmpty ? "Untitled.pdf" : baseName + ".pdf"
    }
}
