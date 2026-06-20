import LeafMarkCore
import SwiftUI

struct DirectorySidebarView: View {
    let isVisible: Bool
    let tree: DirectoryTreeNode?
    let selectedFileURL: URL?
    let openDocument: (URL) -> Void

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
                            openDocument: openDocument
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

    var body: some View {
        switch node.kind {
        case .folder:
            DisclosureGroup {
                ForEach(node.children) { child in
                    DirectoryTreeNodeView(
                        node: child,
                        selectedFileURL: selectedFileURL,
                        openDocument: openDocument
                    )
                }
            } label: {
                Label(node.name, systemImage: "folder")
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
        }
    }
}
