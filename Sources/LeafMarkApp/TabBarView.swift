import LeafMarkCore
import SwiftUI
import UniformTypeIdentifiers

struct TabBarView: View {
    let tabs: [DocumentTab]
    @Binding var selectedTabID: DocumentTab.ID?
    let closeTab: (DocumentTab.ID) -> Void
    let closeOtherTabs: (DocumentTab.ID) -> Void
    let moveTab: (DocumentTab.ID, DocumentTab.ID) -> Void
    @State private var draggingTabID: DocumentTab.ID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tabs) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.bar)
    }

    private func tabButton(for tab: DocumentTab) -> some View {
        HStack(spacing: 6) {
            Button {
                selectedTabID = tab.id
            } label: {
                Text(tab.windowTitleFragment)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .buttonStyle(.plain)

            Button {
                closeTab(tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tab.id == selectedTabID ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button("Close Tab") {
                closeTab(tab.id)
            }
            Button("Close Others") {
                closeOtherTabs(tab.id)
            }
        }
        .onDrag {
            draggingTabID = tab.id
            return NSItemProvider(object: tab.id.uuidString as NSString)
        }
        .onDrop(
            of: [UTType.text],
            delegate: TabDropDelegate(
                targetTabID: tab.id,
                draggingTabID: $draggingTabID,
                moveTab: moveTab
            )
        )
    }
}

private struct TabDropDelegate: DropDelegate {
    let targetTabID: DocumentTab.ID
    @Binding var draggingTabID: DocumentTab.ID?
    let moveTab: (DocumentTab.ID, DocumentTab.ID) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingTabID, draggingTabID != targetTabID else { return }
        moveTab(draggingTabID, targetTabID)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingTabID = nil
        return true
    }
}
