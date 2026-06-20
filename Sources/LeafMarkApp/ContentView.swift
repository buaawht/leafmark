import LeafMarkCore
import AppKit
import SwiftUI

struct ContentView: View {
    @Binding var pendingOpenedURLs: [URL]

    @State private var model = DocumentViewModel()
    @State private var renderedHTML = ""
    @State private var isPreviewVisible = true
    @State private var copyRequested = false
    @State private var renderTask: Task<Void, Never>?

    private let renderer = MarkdownRenderService()
    private let fileDialogService: any FileDialogService = AppKitFileDialogService()

    var body: some View {
        content
            .navigationTitle(model.windowTitle)
            .toolbar {
                documentToolbar
            }
            .task {
                renderPreview()
            }
            .onChange(of: model.markdownText) {
                schedulePreviewRender()
            }
            .onChange(of: pendingOpenedURLs) {
                openPendingDocumentFromFinder()
            }
            .onDisappear {
                renderTask?.cancel()
            }
            .background(WindowCloseGuard(shouldClose: {
                handleUnsavedChangesIfNeeded()
            }))
    }

    private var content: some View {
        VStack(spacing: 0) {
            documentSplitView
            Divider()
            statusBar
        }
    }

    private var documentSplitView: some View {
        HSplitView {
            TextEditor(text: $model.markdownText)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .frame(minWidth: 320)

            if isPreviewVisible {
                MarkdownPreviewView(
                    html: renderedHTML,
                    baseURL: model.baseFileURLForPreview,
                    copyRequested: $copyRequested
                )
                .frame(minWidth: 320)
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
                isPreviewVisible.toggle()
            } label: {
                Label("Toggle Preview", systemImage: "sidebar.right")
            }

            Button {
                copyRequested = true
            } label: {
                Label("Copy Rendered", systemImage: "doc.on.doc")
            }
            .disabled(!isPreviewVisible || renderedHTML.isEmpty)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text(model.saveStatusText)

            Divider()
                .frame(height: 14)

            Text("\(model.wordCount) words")
            Text("\(model.characterCount) characters")

            Divider()
                .frame(height: 14)

            Text(model.pathSummary)
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

    private func newDocument() {
        guard handleUnsavedChangesIfNeeded() else { return }
        model.newWelcomeDocument()
        renderPreview()
    }

    private func openDocument() {
        guard handleUnsavedChangesIfNeeded() else { return }
        guard let url = fileDialogService.chooseOpenFile() else { return }

        openDocument(at: url)
    }

    private func openPendingDocumentFromFinder() {
        guard let url = pendingOpenedURLs.first else { return }

        pendingOpenedURLs.removeAll()
        openDocumentFromFinder(url)
    }

    private func openDocumentFromFinder(_ url: URL) {
        guard handleUnsavedChangesIfNeeded() else { return }

        openDocument(at: url)
    }

    private func openDocument(at url: URL) {
        do {
            try model.open(url: url)
            renderPreview()
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func saveDocument() -> Bool {
        guard model.fileURL != nil else {
            return saveDocumentAs()
        }

        do {
            _ = try model.save()
            renderPreview()
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    private func saveDocumentAs() -> Bool {
        guard let url = fileDialogService.chooseSaveFile(defaultName: model.displayName) else {
            return false
        }

        do {
            try model.saveAs(url: url)
            renderPreview()
            return true
        } catch {
            showError(error.localizedDescription)
            return false
        }
    }

    private func handleUnsavedChangesIfNeeded() -> Bool {
        guard model.hasUnsavedChanges else { return true }

        switch AppDialogCoordinator.askUnsavedChanges(displayName: model.displayName) {
        case .save:
            return saveDocument()
        case .discard:
            return true
        case .cancel:
            return false
        }
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
        do {
            renderedHTML = try renderer.render(
                model.markdownText,
                baseFileURL: model.baseFileURLForPreview
            )
            model.errorMessage = nil
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    private func showError(_ message: String) {
        model.errorMessage = message
        AppDialogCoordinator.showError(message)
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
