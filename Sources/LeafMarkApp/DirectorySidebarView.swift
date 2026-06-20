import LeafMarkCore
import SwiftUI

struct DirectorySidebarView: View {
    let isVisible: Bool
    let tree: DirectoryTreeNode?
    let selectedFileURL: URL?
    let openDocument: (URL) -> Void
    let createFile: (URL) -> Void
    let createFolder: (URL) -> Void
    let renameItem: (DirectoryTreeNode) -> Void
    let deleteItem: (DirectoryTreeNode) -> Void
    let revealInFinder: (URL) -> Void
    let copyAbsolutePath: (URL) -> Void
    let closeWorkspace: () -> Void

    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 8) {
                Text("Files")
                    .font(.headline)

                if let tree {
                    List {
                        DirectoryTreeNodeView(
                            node: tree,
                            selectedFileURL: selectedFileURL,
                            openDocument: openDocument,
                            createFile: createFile,
                            createFolder: createFolder,
                            renameItem: renameItem,
                            deleteItem: deleteItem,
                            revealInFinder: revealInFinder,
                            copyAbsolutePath: copyAbsolutePath,
                            closeWorkspace: closeWorkspace,
                            isRoot: true
                        )
                    }
                    .listStyle(.sidebar)
                } else {
                    Text("Open a folder to browse Markdown files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(12)
            .frame(minWidth: 180, idealWidth: 220, maxWidth: 280, maxHeight: .infinity, alignment: .topLeading)
            .background(.regularMaterial)
        }
    }
}

private struct DirectoryTreeNodeView: View {
    let node: DirectoryTreeNode
    let selectedFileURL: URL?
    let openDocument: (URL) -> Void
    let createFile: (URL) -> Void
    let createFolder: (URL) -> Void
    let renameItem: (DirectoryTreeNode) -> Void
    let deleteItem: (DirectoryTreeNode) -> Void
    let revealInFinder: (URL) -> Void
    let copyAbsolutePath: (URL) -> Void
    let closeWorkspace: () -> Void
    let isRoot: Bool

    var body: some View {
        switch node.kind {
        case .folder:
            DisclosureGroup {
                ForEach(node.children) { child in
                    DirectoryTreeNodeView(
                        node: child,
                        selectedFileURL: selectedFileURL,
                        openDocument: openDocument,
                        createFile: createFile,
                        createFolder: createFolder,
                        renameItem: renameItem,
                        deleteItem: deleteItem,
                        revealInFinder: revealInFinder,
                        copyAbsolutePath: copyAbsolutePath,
                        closeWorkspace: closeWorkspace,
                        isRoot: false
                    )
                }
            } label: {
                Label(node.name, systemImage: "folder")
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("New File") {
                            createFile(node.url)
                        }
                        Button("New Folder") {
                            createFolder(node.url)
                        }
                        Divider()
                        Button("Reveal in Finder") {
                            revealInFinder(node.url)
                        }
                        Button("Copy Absolute Path") {
                            copyAbsolutePath(node.url)
                        }
                        Divider()
                        Button("Rename") {
                            renameItem(node)
                        }
                        if isRoot {
                            Button("Close Workspace") {
                                closeWorkspace()
                            }
                        }
                        Button("Move to Trash", role: .destructive) {
                            deleteItem(node)
                        }
                    }
            }
        case .document:
            Button {
                openDocument(node.url)
            } label: {
                Label(node.name, systemImage: "doc.text")
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .foregroundStyle(node.url == selectedFileURL ? Color.accentColor : Color.primary)
            .contextMenu {
                Button("Reveal in Finder") {
                    revealInFinder(node.url)
                }
                Button("Copy Absolute Path") {
                    copyAbsolutePath(node.url)
                }
                Divider()
                Button("Rename") {
                    renameItem(node)
                }
                Button("Move to Trash", role: .destructive) {
                    deleteItem(node)
                }
            }
        case .unsupportedFile:
            Label(node.name, systemImage: "doc")
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .contextMenu {
                    Button("Reveal in Finder") {
                        revealInFinder(node.url)
                    }
                    Button("Copy Absolute Path") {
                        copyAbsolutePath(node.url)
                    }
                    Divider()
                    Button("Rename") {
                        renameItem(node)
                    }
                    Button("Move to Trash", role: .destructive) {
                        deleteItem(node)
                    }
                }
        }
    }
}
