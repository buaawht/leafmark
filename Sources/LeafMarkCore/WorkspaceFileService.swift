import Foundation

public struct WorkspaceFileService {
    public enum WorkspaceError: LocalizedError, Equatable {
        case notDirectory(URL)
        case itemAlreadyExists(String)
        case itemDoesNotExist(URL)
        case emptyName

        public var errorDescription: String? {
            switch self {
            case .notDirectory(let url):
                return "Not a folder: \(url.lastPathComponent)"
            case .itemAlreadyExists(let name):
                return "An item named \(name) already exists."
            case .itemDoesNotExist(let url):
                return "Item does not exist: \(url.lastPathComponent)"
            case .emptyName:
                return "Name cannot be empty."
            }
        }
    }

    private let fileManager: FileManager
    private let trashHandler: (URL) throws -> Void

    public init(
        fileManager: FileManager = .default,
        trashHandler: ((URL) throws -> Void)? = nil
    ) {
        self.fileManager = fileManager
        self.trashHandler = trashHandler ?? { url in
            var resultingURL: NSURL?
            try FileManager.default.trashItem(
                at: url,
                resultingItemURL: &resultingURL
            )
        }
    }

    public func scanDirectory(root: URL) throws -> DirectoryTreeNode {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw WorkspaceError.notDirectory(root)
        }

        return try scanFolder(root)
    }

    private func scanFolder(_ folder: URL) throws -> DirectoryTreeNode {
        let childURLs = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        )

        let children = try childURLs
            .filter(shouldInclude)
            .compactMap { url -> DirectoryTreeNode? in
                let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                if values.isDirectory == true {
                    return try scanFolder(url)
                }
                guard DocumentFileService.isSupportedDocument(url) else {
                    return nil
                }
                return DirectoryTreeNode(url: url, kind: .document)
            }
            .sorted(by: sortNodes)

        return DirectoryTreeNode(url: folder, kind: .folder, children: children)
    }

    private func shouldInclude(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        guard !name.hasPrefix(".") else { return false }
        guard ![".build", "build"].contains(name) else { return false }
        return true
    }

    private func sortNodes(_ lhs: DirectoryTreeNode, _ rhs: DirectoryTreeNode) -> Bool {
        if lhs.kind != rhs.kind {
            return lhs.kind == .folder
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    public func createMarkdownFile(named name: String, in directory: URL) throws -> URL {
        let fileName = normalizedMarkdownFileName(name)
        let url = directory.appendingPathComponent(fileName)
        try ensureCreatable(url: url)
        try "".write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    public func createFolder(named name: String, in directory: URL) throws -> URL {
        let folderName = try normalizedItemName(name)
        let url = directory.appendingPathComponent(folderName)
        try ensureCreatable(url: url)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
        return url
    }

    public func renameItem(at url: URL, to newName: String) throws -> URL {
        guard fileManager.fileExists(atPath: url.path) else {
            throw WorkspaceError.itemDoesNotExist(url)
        }

        let name = try normalizedItemName(newName)
        let destination = url.deletingLastPathComponent().appendingPathComponent(name)
        try ensureCreatable(url: destination)
        try fileManager.moveItem(at: url, to: destination)
        return destination
    }

    public func trashItem(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw WorkspaceError.itemDoesNotExist(url)
        }
        try trashHandler(url)
    }

    private func normalizedMarkdownFileName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Untitled.md" }
        let url = URL(fileURLWithPath: trimmed)
        if DocumentFileService.isSupportedDocument(url) {
            return trimmed
        }
        return trimmed + ".md"
    }

    private func normalizedItemName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw WorkspaceError.emptyName
        }
        return trimmed
    }

    private func ensureCreatable(url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            throw WorkspaceError.itemAlreadyExists(url.lastPathComponent)
        }
    }
}
