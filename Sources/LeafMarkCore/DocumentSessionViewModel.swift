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
        let welcomeTab = DocumentTab(markdownText: WelcomeDocument.text, isWelcomeDocument: true)
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

    public func tabID(forFileURL fileURL: URL) -> DocumentTab.ID? {
        tabs.first { $0.fileURL == fileURL }?.id
    }

    public func updateTabFileURL(from oldURL: URL, to newURL: URL) {
        tabs
            .filter { $0.fileURL == oldURL }
            .forEach { $0.updateFileURL(newURL) }
    }

    public func updateTabFileURLs(movingItemAt oldURL: URL, to newURL: URL) {
        let oldPath = oldURL.standardizedFileURL.path
        let oldPrefix = oldPath + "/"

        for tab in tabs {
            guard let fileURL = tab.fileURL?.standardizedFileURL else { continue }
            let filePath = fileURL.path

            if filePath == oldPath {
                tab.updateFileURL(newURL)
            } else if filePath.hasPrefix(oldPrefix) {
                let relativePath = String(filePath.dropFirst(oldPrefix.count))
                tab.updateFileURL(newURL.appendingPathComponent(relativePath))
            }
        }
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
            let welcomeTab = DocumentTab(markdownText: WelcomeDocument.text, isWelcomeDocument: true)
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
            let welcomeTab = DocumentTab(markdownText: WelcomeDocument.text, isWelcomeDocument: true)
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

    public func moveTab(id sourceID: DocumentTab.ID?, before targetID: DocumentTab.ID?) {
        guard let sourceID,
              let targetID,
              sourceID != targetID,
              let sourceIndex = tabs.firstIndex(where: { $0.id == sourceID }),
              let targetIndex = tabs.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        let tab = tabs.remove(at: sourceIndex)
        let adjustedTargetIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        tabs.insert(tab, at: adjustedTargetIndex)
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
