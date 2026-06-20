import Foundation
import Observation

@MainActor
@Observable
public final class DocumentSessionViewModel {
    public private(set) var tabs: [DocumentTab]
    public var selectedTabID: DocumentTab.ID?
    public var workspaceRootURL: URL?
    public var errorMessage: String?

    public init() {
        let welcomeTab = DocumentTab()
        self.tabs = [welcomeTab]
        self.selectedTabID = welcomeTab.id
        self.workspaceRootURL = nil
    }

    public var selectedTab: DocumentTab? {
        guard let selectedTabID else { return tabs.first }
        return tabs.first { $0.id == selectedTabID }
    }

    public var selectedTabIndex: Int? {
        guard let selectedTabID else { return tabs.indices.first }
        return tabs.firstIndex { $0.id == selectedTabID }
    }

    public var windowTitle: String {
        "\(selectedTab?.windowTitleFragment ?? "Welcome") — LeafMark"
    }

    public func tab(id: DocumentTab.ID?) -> DocumentTab? {
        guard let id else { return nil }
        return tabs.first { $0.id == id }
    }

    public func newTab() {
        let tab = DocumentTab()
        tabs.append(tab)
        selectedTabID = tab.id
    }

    public func openTab(
        url: URL,
        fileService: DocumentFileService = DocumentFileService()
    ) throws {
        if let existing = tabs.first(where: { $0.fileURL == url }) {
            selectedTabID = existing.id
            return
        }

        let text = try fileService.read(from: url)
        let tab = DocumentTab(markdownText: text, fileURL: url)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    @discardableResult
    public func closeTab(id: DocumentTab.ID?) -> Bool {
        guard let id,
              let index = tabs.firstIndex(where: { $0.id == id }),
              !tabs[index].hasUnsavedChanges
        else {
            return false
        }

        tabs.remove(at: index)
        if tabs.isEmpty {
            let welcomeTab = DocumentTab()
            tabs = [welcomeTab]
            selectedTabID = welcomeTab.id
        } else if selectedTabID == id {
            selectedTabID = tabs[min(index, tabs.count - 1)].id
        }
        return true
    }

    @discardableResult
    public func discardTab(id: DocumentTab.ID?) -> Bool {
        guard let id,
              let index = tabs.firstIndex(where: { $0.id == id })
        else {
            return false
        }

        tabs.remove(at: index)
        if tabs.isEmpty {
            let welcomeTab = DocumentTab()
            tabs = [welcomeTab]
            selectedTabID = welcomeTab.id
        } else if selectedTabID == id {
            selectedTabID = tabs[min(index, tabs.count - 1)].id
        }
        return true
    }

    @discardableResult
    public func closeOtherTabs(keeping id: DocumentTab.ID?) -> Int {
        guard let id,
              let selected = tabs.first(where: { $0.id == id })
        else {
            return 0
        }

        let closableTabs = tabs.filter { $0.id != id && !$0.hasUnsavedChanges }
        tabs = tabs.filter { $0.id == id || $0.hasUnsavedChanges }
        selectedTabID = selected.id
        return closableTabs.count
    }

    public func saveSelected(
        fileService: DocumentFileService = DocumentFileService()
    ) throws -> Bool {
        guard let selectedTab else { return false }
        guard let fileURL = selectedTab.fileURL else { return false }
        try fileService.write(selectedTab.markdownText, to: fileURL)
        selectedTab.markSaved(to: fileURL)
        return true
    }

    public func saveSelectedAs(
        url: URL,
        fileService: DocumentFileService = DocumentFileService()
    ) throws {
        guard let selectedTab else { return }
        try fileService.write(selectedTab.markdownText, to: url)
        selectedTab.markSaved(to: url)
    }
}
