# LeafMark macOS V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build LeafMark V1: a lightweight local macOS Markdown editor with open/edit/live preview/save/save-as, Finder double-click opening, and formatted copy from preview.

**Architecture:** Use a SwiftPM package as the source of truth, with one executable SwiftUI target for the app and one library target for testable document/rendering/file logic. The app uses a single SwiftUI window with editor/preview split; Markdown rendering is isolated behind `MarkdownRenderService`; preview is a `WKWebView`; app bundle creation is handled by a small local script that injects document type metadata for Finder double-click.

**Tech Stack:** Swift 5.9+, macOS 14+, SwiftUI, WebKit/WKWebView, AppKit panels/pasteboard, SwiftPM, `swift-markdown` package wrapped by LeafMark rendering code, XCTest.

---

## Assumptions and success criteria

- The repository starts from the current clean state: only `docs/superpowers/specs/2026-06-20-leafmark-design.md` exists.
- This plan intentionally avoids App Store distribution, signing, notarization, cloud sync, accounts, plugins, multi-tab UI, syntax highlighting, scroll sync, and complex themes.
- The implementation should be small and local-first. If a step tempts a larger abstraction, stop and keep the V1 path.
- Because this environment currently has Command Line Tools but not full Xcode selected, automated verification focuses on `swift test` and `swift build`. Full Finder double-click verification requires launching the generated `.app` on a Mac desktop session.
- Rendering dependency choice: use `swift-markdown` only behind `MarkdownRenderService`. If implementation discovers that table support is insufficient in the selected version, do not leak the dependency into UI; replace only the service internals or add a tiny table pass inside the service.

## File structure map

- Create: `Package.swift` — SwiftPM manifest with executable app target, testable core library, tests, and Markdown package dependency.
- Create: `Sources/LeafMarkCore/DocumentViewModel.swift` — current document state, dirty tracking, word/character counts, title/path display helpers, new/open/save orchestration hooks.
- Create: `Sources/LeafMarkCore/DocumentFileService.swift` — UTF-8 file read/write and supported extension validation.
- Create: `Sources/LeafMarkCore/FileDialogService.swift` — protocol for open/save panels, plus AppKit implementation compiled on macOS.
- Create: `Sources/LeafMarkCore/MarkdownRenderService.swift` — protocol plus concrete renderer returning full HTML and CSS.
- Create: `Sources/LeafMarkCore/WelcomeDocument.swift` — welcome sample Markdown.
- Create: `Sources/LeafMarkCore/UnsavedChangesDecision.swift` — simple enum for Save / Don't Save / Cancel flow.
- Create: `Sources/LeafMarkApp/LeafMarkApp.swift` — SwiftUI app entry, commands, Finder open event wiring.
- Create: `Sources/LeafMarkApp/ContentView.swift` — single-window layout, toolbar, split editor/preview, status area, alerts.
- Create: `Sources/LeafMarkApp/MarkdownPreviewView.swift` — `WKWebView` bridge, external-link policy, HTML loading, formatted copy support.
- Create: `Sources/LeafMarkApp/AppDialogCoordinator.swift` — bridges ViewModel decisions to AppKit alerts/panels without putting AppKit code inside the core model.
- Create: `Resources/LeafMark.app/Info.plist` — app metadata and document type declarations for `.md`, `.markdown`, `.txt`.
- Create: `scripts/build_app_bundle.sh` — builds release executable and assembles `build/LeafMark.app`.
- Create tests under `Tests/LeafMarkCoreTests/` for rendering, document state, file service, and welcome document.

---

## Task 1: SwiftPM skeleton and buildable targets

**Files:**
- Create: `Package.swift`
- Create: `Sources/LeafMarkCore/WelcomeDocument.swift`
- Create: `Sources/LeafMarkApp/LeafMarkApp.swift`
- Create: `Sources/LeafMarkApp/ContentView.swift`
- Create: `Tests/LeafMarkCoreTests/WelcomeDocumentTests.swift`

- [ ] **Step 1: Create the SwiftPM manifest**

Create `Package.swift`:

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LeafMark",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LeafMark", targets: ["LeafMarkApp"]),
        .library(name: "LeafMarkCore", targets: ["LeafMarkCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "LeafMarkCore",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .executableTarget(
            name: "LeafMarkApp",
            dependencies: ["LeafMarkCore"]
        ),
        .testTarget(
            name: "LeafMarkCoreTests",
            dependencies: ["LeafMarkCore"]
        )
    ]
)
```

- [ ] **Step 2: Add the welcome document**

Create `Sources/LeafMarkCore/WelcomeDocument.swift`:

```swift
import Foundation

public enum WelcomeDocument {
    public static let text = """
    # Welcome to LeafMark

    LeafMark is a lightweight local Markdown editor for macOS.

    ## Try common Markdown

    - Edit on the left
    - Preview on the right
    - Save when you are ready

    > A quiet local tool for writing and reading Markdown.

    [OpenAI](https://openai.com)

    | Feature | Status |
    | --- | --- |
    | Tables | Supported |
    | Links | Supported |
    | Images | Supported |

    ```swift
    let leaf = "mark"
    print(leaf)
    ```

    ![Local image example](example.png)
    """
}
```

- [ ] **Step 3: Add a minimal SwiftUI app entry**

Create `Sources/LeafMarkApp/LeafMarkApp.swift`:

```swift
import SwiftUI

@main
struct LeafMarkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowResizability(.contentSize)
    }
}
```

- [ ] **Step 4: Add a minimal content view**

Create `Sources/LeafMarkApp/ContentView.swift`:

```swift
import LeafMarkCore
import SwiftUI

struct ContentView: View {
    @State private var text = WelcomeDocument.text

    var body: some View {
        NavigationSplitView {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding(8)
        } detail: {
            ScrollView {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .navigationTitle("LeafMark")
    }
}
```

- [ ] **Step 5: Add a smoke test**

Create `Tests/LeafMarkCoreTests/WelcomeDocumentTests.swift`:

```swift
import XCTest
@testable import LeafMarkCore

final class WelcomeDocumentTests: XCTestCase {
    func testWelcomeDocumentShowsCoreMarkdownFeatures() {
        let text = WelcomeDocument.text

        XCTAssertTrue(text.contains("# Welcome to LeafMark"))
        XCTAssertTrue(text.contains("| Feature | Status |"))
        XCTAssertTrue(text.contains("![Local image example]"))
        XCTAssertTrue(text.contains("```swift"))
    }
}
```

- [ ] **Step 6: Verify the skeleton**

Run:

```bash
swift test
swift build
```

Expected: `WelcomeDocumentTests` passes and the `LeafMark` executable builds successfully.

- [ ] **Step 7: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "Add SwiftPM LeafMark skeleton"
```

---

## Task 2: Core document state and dirty tracking

**Files:**
- Create: `Sources/LeafMarkCore/DocumentViewModel.swift`
- Create: `Sources/LeafMarkCore/UnsavedChangesDecision.swift`
- Create: `Tests/LeafMarkCoreTests/DocumentViewModelTests.swift`

- [ ] **Step 1: Write failing tests for document state**

Create `Tests/LeafMarkCoreTests/DocumentViewModelTests.swift` with tests for welcome defaults, dirty tracking, file loading baseline reset, word/character counts, and home-relative path summaries:

```swift
import XCTest
@testable import LeafMarkCore

@MainActor
final class DocumentViewModelTests: XCTestCase {
    func testStartsWithWelcomeDocumentAndNoFileURL() {
        let model = DocumentViewModel()

        XCTAssertEqual(model.markdownText, WelcomeDocument.text)
        XCTAssertNil(model.fileURL)
        XCTAssertEqual(model.displayName, "Welcome")
        XCTAssertFalse(model.hasUnsavedChanges)
    }

    func testEditingMarksDocumentDirty() {
        let model = DocumentViewModel()

        model.markdownText = "# Changed"

        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertEqual(model.saveStatusText, "Unsaved")
    }

    func testLoadingFileResetsBaseline() {
        let model = DocumentViewModel()
        let url = URL(fileURLWithPath: "/tmp/notes.md")

        model.load(text: "# Notes", from: url)

        XCTAssertEqual(model.markdownText, "# Notes")
        XCTAssertEqual(model.fileURL, url)
        XCTAssertEqual(model.displayName, "notes.md")
        XCTAssertFalse(model.hasUnsavedChanges)
    }

    func testWordAndCharacterCounts() {
        let model = DocumentViewModel()

        model.markdownText = "Hello LeafMark\n\n你好"

        XCTAssertEqual(model.wordCount, 2)
        XCTAssertEqual(model.characterCount, 18)
    }

    func testPathSummaryUsesTildeForHomeDirectory() {
        let model = DocumentViewModel()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("Documents/notes.md")

        model.load(text: "# Notes", from: url)

        XCTAssertEqual(model.pathSummary, "~/Documents/notes.md")
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter DocumentViewModelTests
```

Expected: FAIL because `DocumentViewModel` does not exist.

- [ ] **Step 3: Add model implementation**

Create `Sources/LeafMarkCore/UnsavedChangesDecision.swift` and `Sources/LeafMarkCore/DocumentViewModel.swift` with the minimal public API used by the tests: `markdownText`, `baselineText`, `fileURL`, `errorMessage`, `hasUnsavedChanges`, `displayName`, `windowTitle`, `saveStatusText`, `wordCount`, `characterCount`, `pathSummary`, `baseFileURLForPreview`, `newWelcomeDocument()`, `load(text:from:)`, and `markSaved(to:)`.

Implementation rule: keep it `@MainActor` and `@Observable`, and keep all file I/O out of this file until Task 3.

- [ ] **Step 4: Verify document tests pass**

Run:

```bash
swift test --filter DocumentViewModelTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/LeafMarkCore Tests/LeafMarkCoreTests
git commit -m "Add document state model"
```

---

## Task 3: File read/write service

**Files:**
- Create: `Sources/LeafMarkCore/DocumentFileService.swift`
- Create: `Tests/LeafMarkCoreTests/DocumentFileServiceTests.swift`
- Modify: `Sources/LeafMarkCore/DocumentViewModel.swift`

- [ ] **Step 1: Write failing file service tests**

Create `Tests/LeafMarkCoreTests/DocumentFileServiceTests.swift`:

```swift
import XCTest
@testable import LeafMarkCore

final class DocumentFileServiceTests: XCTestCase {
    func testSupportedMarkdownExtensions() {
        XCTAssertTrue(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.md")))
        XCTAssertTrue(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.markdown")))
        XCTAssertTrue(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.txt")))
        XCTAssertFalse(DocumentFileService.isSupportedDocument(URL(fileURLWithPath: "/tmp/a.pdf")))
    }

    func testReadAndWriteUTF8Markdown() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("notes.md")

        let service = DocumentFileService()
        try service.write("# Hello", to: url)

        XCTAssertEqual(try service.read(from: url), "# Hello")
    }
}
```

- [ ] **Step 2: Implement file service and ViewModel save/open helpers**

Create `DocumentFileService` with `isSupportedDocument(_:)`, `read(from:)`, and `write(_:to:)`. Modify `DocumentViewModel` to add:

```swift
public func open(url: URL, fileService: DocumentFileService = DocumentFileService()) throws
public func save(fileService: DocumentFileService = DocumentFileService()) throws -> Bool
public func saveAs(url: URL, fileService: DocumentFileService = DocumentFileService()) throws
```

The `save()` method returns `false` when there is no current file URL so the UI can route to Save As.

- [ ] **Step 3: Verify**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add Sources/LeafMarkCore Tests/LeafMarkCoreTests
git commit -m "Add Markdown file service"
```

---

## Task 4: Markdown rendering service with full HTML page

**Files:**
- Create: `Sources/LeafMarkCore/MarkdownRenderService.swift`
- Create: `Tests/LeafMarkCoreTests/MarkdownRenderServiceTests.swift`

- [ ] **Step 1: Write failing renderer tests**

Create tests that assert `MarkdownRenderService.render(_:baseFileURL:)` returns a complete HTML document containing rendered heading, strong text, link, blockquote, unordered list, table, escaped raw HTML, and a relative image rewritten from the Markdown file directory.

Use these exact assertions:

```swift
XCTAssertTrue(html.contains("<!doctype html>"))
XCTAssertTrue(html.contains("<h1"))
XCTAssertTrue(html.contains("<strong>bold</strong>"))
XCTAssertTrue(html.contains("https://example.com"))
XCTAssertTrue(html.contains("<blockquote>"))
XCTAssertTrue(html.contains("<ul>"))
XCTAssertTrue(html.contains("<table>"))
XCTAssertTrue(html.contains("file:///tmp/LeafMark/images/cat.png"))
XCTAssertFalse(html.contains("<script>alert"))
XCTAssertTrue(html.contains("&lt;script&gt;"))
```

- [ ] **Step 2: Implement service boundary**

Create `MarkdownRenderService` with:

```swift
public struct MarkdownRenderService {
    public init() {}
    public func render(_ markdown: String, baseFileURL: URL?) throws -> String
}
```

Implementation requirements:

- Use the `Markdown` package only in this file.
- Return a full `<!doctype html>` page.
- Inject lightweight CSS for headings, paragraphs, quotes, inline code, code blocks, tables, images, links, and horizontal rules.
- Escape raw HTML by default.
- Resolve relative image paths against `baseFileURL.deletingLastPathComponent()`.
- Keep external links unchanged.
- Keep renderer internals private.

- [ ] **Step 3: Verify renderer**

Run:

```bash
swift test --filter MarkdownRenderServiceTests
swift test
```

Expected: PASS. If the selected `swift-markdown` version exposes table APIs differently, change only private rendering internals or the dependency version; preserve the public service API and tests.

- [ ] **Step 4: Commit**

```bash
git add Package.swift Sources/LeafMarkCore Tests/LeafMarkCoreTests
git commit -m "Add Markdown render service"
```

---

## Task 5: WKWebView preview, debounce, external links, and formatted copy

**Files:**
- Create: `Sources/LeafMarkApp/MarkdownPreviewView.swift`
- Modify: `Sources/LeafMarkApp/ContentView.swift`

- [ ] **Step 1: Replace placeholder preview with rendered HTML state**

Modify `ContentView` so it owns:

```swift
@State private var model = DocumentViewModel()
@State private var renderedHTML = ""
@State private var isPreviewVisible = true
@State private var copyRequested = false
private let renderer = MarkdownRenderService()
```

Use `HSplitView` with `TextEditor` on the left and `MarkdownPreviewView(html:baseURL:copyRequested:)` on the right when preview is visible.

- [ ] **Step 2: Implement debounce**

In `ContentView`, implement a 200ms render delay. Cancel prior work when a new edit arrives:

```swift
@State private var renderTask: Task<Void, Never>?

private func schedulePreviewRender() {
    renderTask?.cancel()
    renderTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        renderPreview()
    }
}
```

- [ ] **Step 3: Create `MarkdownPreviewView`**

Create an `NSViewRepresentable` wrapper around `WKWebView` that:

- Calls `loadHTMLString(html, baseURL: baseURL?.deletingLastPathComponent())`.
- Uses `WKNavigationDelegate` to open `http` and `https` links through `NSWorkspace.shared.open(url)` and cancel WebView navigation.
- Supports formatted copy by writing both `.html` and `.string` to `NSPasteboard.general`.

- [ ] **Step 4: Build**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/LeafMarkApp
git commit -m "Add WebKit Markdown preview"
```

---

## Task 6: File dialogs, toolbar actions, status area, and alerts

**Files:**
- Create: `Sources/LeafMarkCore/FileDialogService.swift`
- Create: `Sources/LeafMarkApp/AppDialogCoordinator.swift`
- Modify: `Sources/LeafMarkApp/ContentView.swift`

- [ ] **Step 1: Add file dialog protocol and AppKit implementation**

Create `FileDialogService` with:

```swift
public protocol FileDialogService {
    func chooseOpenFile() -> URL?
    func chooseSaveFile(defaultName: String) -> URL?
}
```

Create `AppKitFileDialogService` using `NSOpenPanel` and `NSSavePanel`. Open must allow `.md`, `.markdown`, and `.txt`. Save As must default to `.md`.

- [ ] **Step 2: Add unsaved alert coordinator**

Create `AppDialogCoordinator` with:

```swift
static func askUnsavedChanges(displayName: String) -> UnsavedChangesDecision
static func showError(_ message: String)
```

The unsaved alert must have exactly: `Save`, `Don't Save`, `Cancel`.

- [ ] **Step 3: Wire toolbar actions**

Toolbar must include:

- New
- Open
- Save
- Save As
- Toggle Preview
- Copy Rendered

All destructive replacement actions must call a shared `handleUnsavedChangesIfNeeded()` before proceeding.

- [ ] **Step 4: Add status area**

Add a bottom status bar showing:

- `model.saveStatusText`
- `model.wordCount`
- `model.characterCount`
- `model.pathSummary` with middle truncation

- [ ] **Step 5: Build**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/LeafMarkCore Sources/LeafMarkApp
git commit -m "Add document toolbar and file dialogs"
```

---

## Task 7: Finder open support and app bundle metadata

**Files:**
- Create: `Resources/LeafMark.app/Info.plist`
- Create: `scripts/build_app_bundle.sh`
- Modify: `Sources/LeafMarkApp/LeafMarkApp.swift`
- Modify: `Sources/LeafMarkApp/ContentView.swift`

- [ ] **Step 1: Add app Info.plist with document types**

Create `Resources/LeafMark.app/Info.plist` containing:

- `CFBundleExecutable` = `LeafMark`
- `CFBundleIdentifier` = `local.leafmark.app`
- `CFBundleName` = `LeafMark`
- `CFBundlePackageType` = `APPL`
- `LSMinimumSystemVersion` = `14.0`
- `CFBundleDocumentTypes` for extensions `md`, `markdown`, and `txt` with role `Editor`

- [ ] **Step 2: Add bundle build script**

Create `scripts/build_app_bundle.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/LeafMark.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
swift build -c release --product LeafMark

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/release/LeafMark" "$MACOS_DIR/LeafMark"
cp "Resources/LeafMark.app/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/LeafMark"

echo "$APP_DIR"
```

Then run:

```bash
chmod +x scripts/build_app_bundle.sh
```

- [ ] **Step 3: Add Finder open routing**

Use SwiftUI `.onOpenURL` in `LeafMarkApp` to append opened URLs into `@State private var openedURLs: [URL] = []`, pass that binding to `ContentView`, and let `ContentView` call `openDocumentFromFinder(_:)` after the shared unsaved-changes flow.

- [ ] **Step 4: Build executable and app bundle**

Run:

```bash
swift build
scripts/build_app_bundle.sh
```

Expected: command prints `<repo-root>/build/LeafMark.app`.

- [ ] **Step 5: Manual Finder verification**

Run:

```bash
open build/LeafMark.app
```

Then in Finder, choose a local `.md` file, use “Open With → LeafMark”. Expected: LeafMark opens the file in the single window. If the app is already open with unsaved edits, the Save / Don't Save / Cancel alert appears before replacement.

- [ ] **Step 6: Commit**

```bash
git add Resources scripts Sources/LeafMarkApp
git commit -m "Add app bundle and Finder document opening"
```

---

## Task 8: Close-window unsaved confirmation and final polish

**Files:**
- Modify: `Sources/LeafMarkApp/ContentView.swift`
- Modify: `Tests/LeafMarkCoreTests/DocumentViewModelTests.swift`

- [ ] **Step 1: Add title marker regression test**

Append to `DocumentViewModelTests`:

```swift
func testWindowTitleMarksDirtyDocuments() {
    let model = DocumentViewModel()

    XCTAssertEqual(model.windowTitle, "Welcome — LeafMark")

    model.markdownText = "# Dirty"

    XCTAssertEqual(model.windowTitle, "• Welcome — LeafMark")
}
```

- [ ] **Step 2: Add close-window confirmation**

Add a tiny `NSViewRepresentable` helper named `WindowCloseGuard` in `ContentView.swift`. It should set `window.delegate` and implement:

```swift
func windowShouldClose(_ sender: NSWindow) -> Bool {
    shouldClose()
}
```

Attach it with:

```swift
.background(WindowCloseGuard(shouldClose: {
    handleUnsavedChangesIfNeeded()
}))
```

- [ ] **Step 3: Final automated verification**

Run:

```bash
swift test
swift build
scripts/build_app_bundle.sh
```

Expected: all tests pass, app builds, and `build/LeafMark.app` is produced.

- [ ] **Step 4: Final manual verification checklist**

Use `open build/LeafMark.app`, then verify:

- Welcome document displays on first launch.
- Editing the left pane updates the right preview after a short debounce.
- Preview renders headings, lists, quote, link, table, code block, and image syntax.
- New prompts when current document is dirty.
- Open supports `.md`, `.markdown`, and `.txt`.
- Save writes back to an already-opened file.
- Save As writes a new `.md` file and updates the path status.
- Closing the window with unsaved edits prompts Save / Don't Save / Cancel.
- External preview links open in the system browser.
- Relative local images resolve from the Markdown file's directory.
- Copy Rendered puts HTML and plain text on the pasteboard.
- Finder “Open With → LeafMark” opens a Markdown file.

- [ ] **Step 5: Commit**

```bash
git add Sources Tests
git commit -m "Polish LeafMark document workflow"
```

---

## Self-review against design spec

- App name LeafMark: covered by app entry, window title, app bundle Info.plist.
- SwiftUI App + MarkdownRenderService + WKWebView: covered by Tasks 1, 4, 5.
- Open/edit/live preview/save/save-as: covered by Tasks 2, 3, 5, 6.
- Tables/images/links/quotes/lists/code: covered by renderer tests and welcome document.
- Finder double-click/open-with support: covered by Task 7.
- First launch welcome sample: covered by Task 1 and model default.
- Local image base path: covered by renderer tests and WebView base URL.
- Formatted copy with plaintext fallback: covered by Task 5.
- External links open in system browser: covered by Task 5.
- Unsaved confirmation for New/Open/Close/Finder open: covered by Tasks 6, 7, 8.
- Toolbar and status area: covered by Task 6.
- Non-goals avoided: no App Store, signing, cloud, accounts, collaboration, plugins, knowledge base, tabs, syntax highlighting, scroll sync, complex theme system.

No placeholders remain intentionally. Any dependency API mismatch discovered during implementation must be fixed inside `MarkdownRenderService` while preserving its public interface and tests.
