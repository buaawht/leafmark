import SwiftUI

struct DirectorySidebarView: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 8) {
                Text("Files")
                    .font(.headline)
                Text("Open a folder to browse Markdown files.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(12)
            .frame(minWidth: 180, idealWidth: 220, maxWidth: 280, maxHeight: .infinity, alignment: .topLeading)
            .background(.regularMaterial)
        }
    }
}
