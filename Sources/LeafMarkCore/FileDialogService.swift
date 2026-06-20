import AppKit
import Foundation
import UniformTypeIdentifiers

public protocol FileDialogService {
    func chooseOpenFile() -> URL?
    func chooseSaveFile(defaultName: String) -> URL?
}

public struct AppKitFileDialogService: FileDialogService {
    public init() {}

    public func chooseOpenFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = Self.allowedDocumentTypes

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseSaveFile(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = Self.allowedDocumentTypes
        panel.nameFieldStringValue = Self.defaultMarkdownName(from: defaultName)

        return panel.runModal() == .OK ? panel.url : nil
    }

    private static let allowedDocumentTypes: [UTType] = [
        UTType(filenameExtension: "md")!,
        UTType(filenameExtension: "markdown")!,
        .plainText
    ]

    private static func defaultMarkdownName(from name: String) -> String {
        let url = URL(fileURLWithPath: name)
        guard url.pathExtension.lowercased() == "md" else {
            return url.deletingPathExtension().lastPathComponent + ".md"
        }
        return name
    }
}
