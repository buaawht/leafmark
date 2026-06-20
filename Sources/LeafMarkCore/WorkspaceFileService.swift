import Foundation

public struct WorkspaceFileService {
    public enum WorkspaceError: LocalizedError, Equatable {
        case notDirectory(URL)

        public var errorDescription: String? {
            switch self {
            case .notDirectory(let url):
                return "Not a folder: \(url.lastPathComponent)"
            }
        }
    }

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
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
}
