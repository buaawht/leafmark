import Foundation

public struct DirectoryTreeNode: Identifiable, Equatable {
    public enum Kind: Equatable {
        case folder
        case document
    }

    public let id: URL
    public let url: URL
    public let name: String
    public let kind: Kind
    public var children: [DirectoryTreeNode]

    public init(
        url: URL,
        name: String? = nil,
        kind: Kind,
        children: [DirectoryTreeNode] = []
    ) {
        self.id = url
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.kind = kind
        self.children = children
    }

    public var isFolder: Bool {
        kind == .folder
    }
}
