# LeafMark

LeafMark is a lightweight local-first macOS Markdown editor and previewer.

V0.1.1 focuses on a small local document loop:

- open Markdown or text files
- edit Markdown locally
- preview rendered Markdown in a split view
- save and save as
- manage multiple documents with tabs
- browse and manage a local folder from the file sidebar
- open `.md`, `.markdown`, and `.txt` files through Finder / Open With
- export rendered Markdown to PDF or HTML
- copy rendered content as rich HTML with a plain-text fallback

LeafMark is currently intended for personal local use, not App Store distribution.

## Requirements

- macOS 14 or newer
- Swift toolchain via Xcode or Command Line Tools
- Full Xcode is needed to run XCTest-based tests with `swift test`

## Build

```bash
swift package resolve
swift build
```

## Build the local app bundle

```bash
scripts/build_app_bundle.sh
```

This creates:

```bash
build/LeafMark.app
```

Run it with:

```bash
open build/LeafMark.app
```

## Tests and QA

Automated tests are written with XCTest under `Tests/LeafMarkCoreTests`.

Run them with:

```bash
swift test
```

If the active developer directory only provides Command Line Tools and does not include XCTest, `swift test` may fail with:

```text
no such module 'XCTest'
```

In that case, either install/select full Xcode or rely on build checks plus manual QA for local smoke testing.

QA documents:

- `docs/qa/leafmark-v0.1.1-manual-qa-checklist.md`

## Version workflow

Each version should follow the same release path:

1. Start from a clean, up-to-date `master`.
2. Create a version branch from `master`, usually named `codex/leafmark-vX.Y.Z`.
3. Implement only the planned version scope on that branch.
4. Run developer self-tests before handing the build to manual QA.
5. Record manual QA findings in the version QA document.
6. Fix confirmed issues on the same version branch and re-run relevant checks.
7. When manual QA is accepted, update version metadata and README release notes.
8. Merge the version branch back into local `master`.
9. Push both the version branch and `master` to origin.
10. Create and push the version tag, for example `v0.1.1`.
11. Confirm GitHub's default branch points at `master`.

Do not publish a version from a feature branch only. A release is complete only
after local `master`, remote `origin/master`, and the version tag all point to
the accepted release commit.

## V0.1.1 scope

Included:

- SwiftUI single-window app
- split editor and preview, with optional sidebar and outline
- WKWebView Markdown preview
- Markdown rendering behind `MarkdownRenderService`
- common Markdown features including tables, links, images, quotes, lists, and code blocks
- New / Open / Save / Save As / Toggle Preview / Copy Rendered
- document tabs for multiple Markdown/text files
- folder tree browsing with create, rename, delete, and reveal actions
- appearance mode control: light, dark, or system
- PDF and HTML export
- unsaved-change confirmation for destructive document actions
- local app bundle script and document type metadata

Not included yet:

- App Store release, signing, notarization, or installer
- cloud sync, accounts, collaboration, or plugin system
- syntax highlighting
- scroll sync
- plugin or Git integration

## Follow-up backlog

See `docs/qa/leafmark-v0.1.1-manual-qa-checklist.md` for post-QA notes and follow-up requests.
