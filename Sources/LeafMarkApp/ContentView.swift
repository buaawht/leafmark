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
    @AppStorage("appearancePreference") private var appearancePreferenceRawValue = AppearancePreference.system.rawValue

    private let renderer = MarkdownRenderService()
    private let outlineService = DocumentOutlineService()
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
                openDocument: openDocument(at:)
            )

            TextEditor(text: selectedMarkdownBinding)
                .font(.system(.body, design: .monospaced))
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
                    copyRequested: $copyRequested
                )
            case .outline:
                DocumentOutlineView(outline: currentOutline) { _ in
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

            Button(action: openDocument) {
                Label("Open", systemImage: "folder")
            }

            Button(action: openFolder) {
                Label("Open Folder", systemImage: "folder.badge.plus")
            }

            Button {
                _ = saveDocument()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }

            Button {
                _ = saveDocumentAs()
            } label: {
                Label("Save As", systemImage: "square.and.arrow.down.on.square")
            }
        }

        ToolbarItemGroup {
            Button {
                isSidebarVisible.toggle()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.left")
            }

            Menu {
                Picker("Appearance", selection: $appearancePreferenceRawValue) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Text(preference.displayName).tag(preference.rawValue)
                    }
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }

            Button {
                isPreviewVisible.toggle()
            } label: {
                Label("Toggle Preview", systemImage: "sidebar.right")
            }

            Button {
                copyRequested = true
            } label: {
                Label("Copy Rendered", systemImage: "doc.on.doc")
            }
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
