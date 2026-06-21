# AGENTS.md

Guidance for Codex and other agentic contributors working in this repository.

## Project

LeafMark is a lightweight local macOS Markdown editor and previewer.

The app is intentionally small:

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

## Version workflow

For every version, follow this release flow unless the user explicitly changes it:

1. Start from a clean, up-to-date local `master`.
2. Create a version branch from `master`, usually `codex/leafmark-vX.Y.Z`.
3. Implement the planned scope on the version branch only.
4. Run developer self-tests before asking the user to do manual QA.
5. Keep manual QA findings in the version QA document.
6. Fix confirmed QA issues on the same version branch and re-run relevant checks.
7. After the user accepts the version, update version metadata and README release notes.
8. Merge the accepted version branch back into local `master`.
9. Push both the version branch and `master` to origin.
10. Create and push the version tag, for example `v0.1.1`.
11. Confirm GitHub's default branch points at `master`.

Do not consider a version released while it exists only on a feature branch.
Local `master`, remote `origin/master`, and the version tag must all point to
the accepted release commit.

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

## Product non-goals

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
