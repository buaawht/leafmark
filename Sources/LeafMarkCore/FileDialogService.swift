import AppKit
import Foundation
import UniformTypeIdentifiers

public protocol FileDialogService {
    func chooseOpenItem() -> URL?
    func chooseOpenFile() -> URL?
    func chooseOpenFolder() -> URL?
    func chooseSaveFile(defaultName: String) -> URL?
    func chooseExportMarkdownFile(defaultName: String) -> URL?
    func chooseExportPDFFile(defaultName: String) -> URL?
}

public struct AppKitFileDialogService: FileDialogService {
    public init() {}

    public func chooseOpenItem() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.allowedContentTypes = Self.allowedOpenItemTypes
        panel.prompt = "Open"

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseOpenFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = Self.allowedDocumentTypes

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseOpenFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.allowedContentTypes = [.folder]
        panel.prompt = "Open"

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseSaveFile(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = Self.allowedDocumentTypes
        panel.nameFieldStringValue = Self.defaultMarkdownName(from: defaultName)

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseExportMarkdownFile(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = Self.allowedMarkdownExportTypes
        panel.nameFieldStringValue = Self.defaultMarkdownName(from: defaultName)

        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseExportPDFFile(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = Self.defaultPDFName(from: defaultName)

        return panel.runModal() == .OK ? panel.url : nil
    }

    private static let allowedDocumentTypes: [UTType] = [
        UTType(filenameExtension: "md")!,
        UTType(filenameExtension: "markdown")!,
        .plainText,
        .json,
        .xml,
        .commaSeparatedText,
        .propertyList,
        UTType(filenameExtension: "toml")!,
        UTType(filenameExtension: "yaml")!,
        UTType(filenameExtension: "yml")!,
        UTType(filenameExtension: "log")!,
        UTType(filenameExtension: "ini")!,
        UTType(filenameExtension: "conf")!,
        UTType(filenameExtension: "swift")!,
        UTType(filenameExtension: "py")!,
        UTType(filenameExtension: "js")!,
        UTType(filenameExtension: "ts")!,
        UTType(filenameExtension: "sh")!,
        UTType(filenameExtension: "sql")!
    ]

    private static let allowedOpenItemTypes: [UTType] = allowedDocumentTypes + [
        .folder
    ]

    private static let allowedMarkdownExportTypes: [UTType] = [
        UTType(filenameExtension: "md")!,
        UTType(filenameExtension: "markdown")!
    ]

    private static func defaultMarkdownName(from name: String) -> String {
        let url = URL(fileURLWithPath: name)
        guard DocumentFileService.isSupportedDocument(url) else {
            return url.deletingPathExtension().lastPathComponent + ".md"
        }
        return name
    }

    private static func defaultPDFName(from name: String) -> String {
        let url = URL(fileURLWithPath: name)
        guard url.pathExtension.lowercased() == "pdf" else {
            return url.deletingPathExtension().lastPathComponent + ".pdf"
        }
        return name
    }
}
