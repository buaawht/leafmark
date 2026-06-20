# LeafMark

LeafMark is a lightweight local-first macOS Markdown editor and previewer.

V0.1.0 focuses on a small document loop:

- open Markdown or text files
- edit Markdown locally
- preview rendered Markdown in a split view
- save and save as
- open `.md`, `.markdown`, and `.txt` files through Finder / Open With
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

- `docs/qa/leafmark-v1-qa-checklist.md`
- `docs/qa/leafmark-v1-self-test-2026-06-20.md`

## V0.1.0 scope

Included:

- SwiftUI single-window app
- split editor and preview
- WKWebView Markdown preview
- Markdown rendering behind `MarkdownRenderService`
- common Markdown features including tables, links, images, quotes, lists, and code blocks
- New / Open / Save / Save As / Toggle Preview / Copy Rendered
- unsaved-change confirmation for destructive document actions
- local app bundle script and document type metadata

Not included yet:

- App Store release, signing, notarization, or installer
- cloud sync, accounts, collaboration, or plugin system
- multi-tab editing
- syntax highlighting
- scroll sync
- complex themes

## Follow-up backlog

See `docs/qa/leafmark-v1-qa-checklist.md` for post-QA notes and follow-up requests.
