import LeafMarkCore
import SwiftUI

struct DocumentOutlineView: View {
    let outline: [DocumentOutlineNode]
    let selectHeading: (DocumentOutlineNode) -> Void

    var body: some View {
        Group {
            if outline.isEmpty {
                ContentUnavailableView(
                    "No headings",
                    systemImage: "list.bullet.indent",
                    description: Text("Add Markdown headings to build an outline.")
                )
            } else {
                List(outline) { node in
                    Button {
                        selectHeading(node)
                    } label: {
                        Text(node.title)
                            .lineLimit(1)
                            .padding(.leading, CGFloat(max(0, node.level - 1)) * 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
