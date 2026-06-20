import AppKit
import LeafMarkCore
import SwiftUI

struct ContentView: View {
    @Binding var pendingOpenedURLs: [URL]

    @State private var session = DocumentSessionViewModel()
    @State private var isSidebarVisible = true
    @State private var isPreviewVisible = true
    @State private var rightPanelMode = RightPanelMode.preview
    @State private var copyRequested = false
    @State private var directoryTree: DirectoryTreeNode?
    @State private var renderTask: Task<Void, Never>?
    @State private var editorScrollPercentage = 0.0
    @State private var requestedEditorLine: Int?
    @State private var previewScrollTargetID: String?
    @State private var pdfExportURL: URL?
    @AppStorage("appearancePreference") private var appearancePreferenceRawValue = AppearancePreference.system.rawValue

    private let renderer = MarkdownRenderService()
    private let outlineService = DocumentOutlineService()
    private let exportService = ExportService()
    private let workspaceFileService = WorkspaceFileService()
    private let fileDialogService: any FileDialogService = AppKitFileDialogService()

    var body: some View {
        content
            .navigationTitle(session.windowTitle)
            .toolbar {
                documentToolbar
            }
            .task {
                renderPreview()
            }
            .onChange(of: session.selectedTabID) {
                renderPreview()
            }
            .onChange(of: pendingOpenedURLs) {
                openPendingDocumentFromFinder()
            }
            .onChange(of: appearancePreferenceRawValue) {
                renderPreview()
            }
            .onDisappear {
                renderTask?.cancel()
            }
            .background(WindowCloseGuard(shouldClose: {
                handleAllUnsavedChangesIfNeeded()
            }))
            .preferredColorScheme(preferredColorScheme)
    }

    private var content: some View {
        VStack(spacing: 0) {
            TabBarView(
                tabs: session.tabs,
                selectedTabID: $session.selectedTabID,
                closeTab: closeTab,
                closeOtherTabs: closeOtherTabs
            )
            Divider()
            documentSplitView
            Divider()
            statusBar
        }
    }

    private var documentSplitView: some View {
        HSplitView {
            DirectorySidebarView(
                isVisible: isSidebarVisible,
                tree: directoryTree,
                selectedFileURL: session.selectedTab?.fileURL,
                openDocument: openDocument(at:),
                createFile: createFile(in:),
                createFolder: createFolder(in:),
                renameItem: renameItem(_:),
                deleteItem: deleteItem(_:)
            )

            EditorTextView(
                text: selectedMarkdownBinding,
                scrollPercentage: $editorScrollPercentage,
                requestedLine: $requestedEditorLine
            )
                .padding(8)
                .frame(minWidth: 320)

            if isPreviewVisible {
                rightPanel
                    .frame(minWidth: 320)
            }
        }
    }

    private var rightPanel: some View {
        VStack(spacing: 0) {
            Picker("Right Panel", selection: $rightPanelMode) {
                ForEach(RightPanelMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            switch rightPanelMode {
            case .preview:
                MarkdownPreviewView(
                    html: session.selectedTab?.renderedHTML ?? "",
                    baseURL: session.selectedTab?.baseFileURLForPreview,
                    copyRequested: $copyRequested,
                    scrollPercentage: $editorScrollPercentage,
                    scrollTargetID: $previewScrollTargetID,
                    pdfExportURL: $pdfExportURL
                )
            case .outline:
                DocumentOutlineView(outline: currentOutline) { node in
                    requestedEditorLine = node.line
                    previewScrollTargetID = node.slug
                    rightPanelMode = .preview
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var documentToolbar: some ToolbarContent {
        ToolbarItemGroup {
            Button(action: newDocument) {
                Label("New", systemImage: "doc")
            }
            .labelStyle(.titleAndIcon)

            Button(action: openDocument) {
                Label("Open", systemImage: "folder")
            }
            .labelStyle(.titleAndIcon)

            Button(action: openFolder) {
                Label("Open Folder", systemImage: "folder.badge.plus")
            }
            .labelStyle(.titleAndIcon)

            Menu {
                Button("Save") {
                    _ = saveDocument()
                }
                Button("Save As") {
                    _ = saveDocumentAs()
                }
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .labelStyle(.titleAndIcon)

            Menu {
                Button("Markdown") {
                    exportMarkdown()
                }
                Button("PDF") {
                    exportPDF()
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .labelStyle(.titleAndIcon)
        }

        ToolbarItemGroup {
            Button {
                isSidebarVisible.toggle()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.left")
            }
            .labelStyle(.titleAndIcon)

            Menu {
                Picker("Appearance", selection: $appearancePreferenceRawValue) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Text(preference.displayName).tag(preference.rawValue)
                    }
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
            .labelStyle(.titleAndIcon)

            Button {
                isPreviewVisible.toggle()
            } label: {
                Label("Toggle Preview", systemImage: "sidebar.right")
            }
            .labelStyle(.titleAndIcon)

            Button {
                copyRequested = true
            } label: {
                Label("Copy Rendered", systemImage: "doc.on.doc")
            }
            .labelStyle(.titleAndIcon)
            .disabled(!isPreviewVisible || session.selectedTab?.renderedHTML.isEmpty != false)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text(session.selectedTab?.saveStatusText ?? "Saved")

            Divider()
                .frame(height: 14)

            Text("\(session.selectedTab?.wordCount ?? 0) words")
            Text("\(session.selectedTab?.characterCount ?? 0) characters")

            Divider()
                .frame(height: 14)

            Text(session.selectedTab?.pathSummary ?? "No file")
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectedMarkdownBinding: Binding<String> {
        Binding(
            get: {
                session.selectedTab?.markdownText ?? ""
            },
            set: { newValue in
                session.selectedTab?.markdownText = newValue
                schedulePreviewRender()
            }
        )
    }

    private var currentOutline: [DocumentOutlineNode] {
        outlineService.parse(session.selectedTab?.markdownText ?? "")
    }

    private func newDocument() {
        session.newTab()
        renderPreview()
    }

    private func openDocument() {
        guard let url = fileDialogService.chooseOpenFile() else { return }

        openDocument(at: url)
    }

    private func openFolder() {
        guard let url = fileDialogService.chooseOpenFolder() else { return }

        do {
            directoryTree = try workspaceFileService.scanDirectory(root: url)
            session.workspaceRootURL = url
            isSidebarVisible = true
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func refreshDirectoryTree() {
        guard let root = session.workspaceRootURL else { return }
        do {
            directoryTree = try workspaceFileService.scanDirectory(root: root)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func createFile(in directory: URL) {
        guard let name = AppDialogCoordinator.askForName(
            title: "New Markdown File",
            message: "Enter a file name.",
            defaultValue: "Untitled.md"
        ) else { return }

        do {
            let url = try workspaceFileService.createMarkdownFile(named: name, in: directory)
            refreshDirectoryTree()
            openDocument(at: url)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func createFolder(in directory: URL) {
        guard let name = AppDialogCoordinator.askForName(
            title: "New Folder",
            message: "Enter a folder name.",
            defaultValue: "New Folder"
        ) else { return }

        do {
            _ = try workspaceFileService.createFolder(named: name, in: directory)
            refreshDirectoryTree()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func renameItem(_ node: DirectoryTreeNode) {
        guard prepareOpenTabsForFileOperation(under: node) else { return }
        guard let newName = AppDialogCoordinator.askForName(
            title: "Rename",
            message: "Enter a new name.",
            defaultValue: node.name
        ) else { return }

        do {
            let newURL = try workspaceFileService.renameItem(at: node.url, to: newName)
            session.updateTabFileURLs(movingItemAt: node.url, to: newURL)
            refreshDirectoryTree()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func deleteItem(_ node: DirectoryTreeNode) {
        guard AppDialogCoordinator.confirmDelete(displayName: node.name, isFolder: node.kind == .folder) else {
            return
        }
        guard prepareOpenTabsForFileOperation(under: node) else { return }

        do {
            let openTabIDs = affectedTabs(for: node).map(\.id)
            try workspaceFileService.trashItem(at: node.url)
            for tabID in openTabIDs {
                _ = session.discardTab(id: tabID)
            }
            refreshDirectoryTree()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func prepareOpenTabsForFileOperation(under node: DirectoryTreeNode) -> Bool {
        for tab in affectedTabs(for: node) where tab.hasUnsavedChanges {
            session.selectedTabID = tab.id
            switch AppDialogCoordinator.askUnsavedChanges(displayName: tab.displayName) {
            case .save:
                guard saveDocument() else { return false }
            case .discard:
                _ = session.discardTab(id: tab.id)
            case .cancel:
                return false
            }
        }
        return true
    }

    private func affectedTabs(for node: DirectoryTreeNode) -> [DocumentTab] {
        let target = node.url.standardizedFileURL
        let targetPath = target.path
        let targetPrefix = targetPath + "/"

        return session.tabs.filter { tab in
            guard let fileURL = tab.fileURL?.standardizedFileURL else { return false }
            switch node.kind {
            case .document:
                return fileURL == target
            case .unsupportedFile:
                return false
            case .folder:
                return fileURL.path == targetPath || fileURL.path.hasPrefix(targetPrefix)
            }
        }
    }

    private func openPendingDocumentFromFinder() {
        guard let url = pendingOpenedURLs.first else { return }

        pendingOpenedURLs.removeAll()
        openDocument(at: url)
    }

    private func openDocument(at url: URL) {
        do {
            try session.openTab(url: url)
            renderPreview()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func saveDocument() -> Bool {
        guard session.selectedTab?.fileURL != nil else {
            return saveDocumentAs()
        }

        do {
            _ = try session.saveSelected()
            renderPreview()
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    private func saveDocumentAs() -> Bool {
        let defaultName = session.selectedTab?.displayName ?? "Untitled.md"
        guard let url = fileDialogService.chooseSaveFile(defaultName: defaultName) else {
            return false
        }

        do {
            try session.saveSelectedAs(url: url)
            renderPreview()
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    private func exportMarkdown() {
        guard let selectedTab = session.selectedTab else { return }
        let defaultName = exportService.markdownExportName(for: selectedTab.displayName)
        guard let url = fileDialogService.chooseExportMarkdownFile(defaultName: defaultName) else {
            return
        }

        do {
            try exportService.exportMarkdown(selectedTab.markdownText, to: url)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func exportPDF() {
        guard let selectedTab = session.selectedTab else { return }
        let defaultName = exportService.pdfExportName(for: selectedTab.displayName)
        guard let url = fileDialogService.chooseExportPDFFile(defaultName: defaultName) else {
            return
        }

        isPreviewVisible = true
        rightPanelMode = .preview
        renderPreview()
        pdfExportURL = url
    }

    private func closeTab(_ id: DocumentTab.ID) {
        guard let tab = session.tab(id: id) else { return }
        if tab.hasUnsavedChanges {
            switch AppDialogCoordinator.askUnsavedChanges(displayName: tab.displayName) {
            case .save:
                session.selectedTabID = id
                guard saveDocument() else { return }
                _ = session.closeTab(id: id)
            case .discard:
                _ = session.discardTab(id: id)
            case .cancel:
                return
            }
        } else {
            _ = session.closeTab(id: id)
        }
        renderPreview()
    }

    private func closeOtherTabs(keeping id: DocumentTab.ID) {
        for tab in session.tabs where tab.id != id {
            closeTab(tab.id)
        }
        session.selectedTabID = id
        renderPreview()
    }

    private func handleAllUnsavedChangesIfNeeded() -> Bool {
        for tab in session.tabs where tab.hasUnsavedChanges {
            session.selectedTabID = tab.id
            switch AppDialogCoordinator.askUnsavedChanges(displayName: tab.displayName) {
            case .save:
                guard saveDocument() else { return false }
            case .discard:
                continue
            case .cancel:
                return false
            }
        }
        return true
    }

    private func schedulePreviewRender() {
        renderTask?.cancel()
        renderTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            renderPreview()
        }
    }

    private func renderPreview() {
        guard let selectedTab = session.selectedTab else { return }
        do {
            selectedTab.renderedHTML = try renderer.render(
                selectedTab.markdownText,
                baseFileURL: selectedTab.baseFileURLForPreview,
                appearance: appearancePreference
            )
            session.errorMessage = nil
        } catch {
            session.errorMessage = error.localizedDescription
        }
    }

    private var appearancePreference: AppearancePreference {
        AppearancePreference(rawValue: appearancePreferenceRawValue) ?? .system
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearancePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private func showError(_ message: String) {
        session.errorMessage = message
        AppDialogCoordinator.showError(message)
    }
}

private enum RightPanelMode: String, CaseIterable, Identifiable {
    case preview
    case outline

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .preview:
            return "Preview"
        case .outline:
            return "Outline"
        }
    }
}

private struct WindowCloseGuard: NSViewRepresentable {
    let shouldClose: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(shouldClose: shouldClose)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.delegate = context.coordinator
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.shouldClose = shouldClose
        DispatchQueue.main.async {
            nsView.window?.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        var shouldClose: () -> Bool

        init(shouldClose: @escaping () -> Bool) {
            self.shouldClose = shouldClose
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            shouldClose()
        }
    }
}
