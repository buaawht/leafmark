# AGENTS.md

Guidance for Codex and other agentic contributors working in this repository.

## Project

LeafMark is a lightweight local macOS Markdown editor and previewer.

The V0.1.0 app is intentionally small:

- SwiftUI app
- independent Markdown rendering service
- WKWebView preview
- local file open/save/save-as
- Finder / Open With support for `.md`, `.markdown`, and `.txt`

Avoid adding large product surfaces unless the user explicitly asks for them.

## Communication

- Use Chinese for user-facing communication by default.
- English technical terms are fine when clearer.
- State assumptions before making non-obvious changes.
- Surface uncertainty instead of guessing.

## Development principles

- Keep changes surgical.
- Match the existing style.
- Do not refactor unrelated code.
- Do not add speculative abstractions or features.
- Every changed line should trace to the current request.
- Preserve user changes in the working tree.
- Do not commit local machine state, personal paths, credentials, or editor session files.

## Local privacy / repo hygiene

Before pushing or opening a PR, scan the working tree for local-only information,
including editor state, private environment files, credentials, and absolute
paths that contain a local username.

Do not commit:

- `.env`
- API keys or tokens
- local absolute paths containing usernames
- `.DS_Store`
- `.build/`
- `build/`
- editor workspace/session state

## Build and verification

Use:

```bash
swift package resolve
swift build
scripts/build_app_bundle.sh
plutil -lint Resources/LeafMark.app/Info.plist build/LeafMark.app/Contents/Info.plist
git diff --check
```

Run tests when a full Xcode/XCTest environment is available:

```bash
swift test
```

If XCTest is unavailable, report that as an environment limitation rather than a passing test result.

## Markdown rendering boundary

Keep Markdown dependency details behind `MarkdownRenderService`.

- UI should not directly use the Markdown package.
- Renderer should not own document state.
- Renderer should not perform file saves.
- WebView should not own document state.

## File and dialog boundaries

- `DocumentViewModel` owns document state and dirty tracking.
- `DocumentFileService` owns UTF-8 file read/write and extension validation.
- AppKit panels and alerts should stay in the app layer.

## Product non-goals for V0.1.0

Do not add unless explicitly requested:

- App Store release workflow
- signing or notarization
- cloud sync
- accounts
- collaboration
- plugin system
- knowledge-base graph features
- syntax highlighting
- scroll sync
- multi-tab editing
- complex themes

Some of these may appear in the post-QA backlog, but they should be planned before implementation.

## Codex model/provider note

Default Codex sessions should keep the built-in OpenAI provider.

For non-OpenAI providers, start Codex with the matching profile instead of trying to switch provider from inside a default session:

```bash
codex --profile deepseek
codex --profile minimax-cn
```

Inside a profile session, `/model` can switch between models served by that same provider. Do not assume `/model deepseek-v4-pro` from a default OpenAI session switches providers.
