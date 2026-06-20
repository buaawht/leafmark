# LeafMark V1 Self-Test Report

日期：2026-06-20

执行者：Codex

分支：

```bash
codex/leafmark-macos-v1
```

## Summary

本次自测覆盖当前环境中可以可靠自动验证的部分：

- Swift package resolve
- Debug build
- Release app bundle build
- Info.plist lint
- App launch smoke
- Open With style launch smoke
- Git artifact hygiene

当前未覆盖或无法可靠自动验证的部分：

- `swift test`：当前环境缺少 XCTest。
- 真实 UI 视觉检查：需要人工确认预览内容、文件面板、alert 按钮、Copy Rendered 粘贴效果。
- Finder 双击默认关联：当前只做了 `open -a ... file.md` 级别 smoke；完整 Finder UI 流程仍需人工 QA。

## Environment

当前 developer directory：

```bash
xcode-select -p
<CommandLineTools developer directory>
```

当前 XCTest 状态：

```bash
xcrun --find xctest
xcrun: error: unable to find utility "xctest", not a developer tool or in PATH
```

结论：当前机器可以 build app，但不能运行 XCTest-based `swift test`。

## Checks run

### 1. App bundle build

Command:

```bash
scripts/build_app_bundle.sh
```

Observed:

```text
Build of product 'LeafMark' complete!
<repo-root>/build/LeafMark.app
```

Result: PASS

### 2. App launch smoke

Command:

```bash
cat > /tmp/leafmark-smoke.md <<'EOF'
# LeafMark Smoke

- Open from terminal
- Preview should render

| Check | Status |
| --- | --- |
| Open | Manual |
EOF

open -n build/LeafMark.app --args /tmp/leafmark-smoke.md
sleep 3
pgrep -fl LeafMark
osascript -e 'tell application "LeafMark" to quit'
```

Observed:

```text
<repo-root>/build/LeafMark.app/Contents/MacOS/LeafMark /tmp/leafmark-smoke.md
```

Result: PASS for app process launch and quit.

Note:

- This validates that the generated `.app` starts.
- This does not prove document open event handling because `--args` passes a process argument, not a Finder document event.

### 3. Open With style launch smoke

Command:

```bash
cat > /tmp/leafmark-openwith-smoke.md <<'EOF'
# LeafMark Open With Smoke

Opened through macOS open service.
EOF

open -n -a "$PWD/build/LeafMark.app" /tmp/leafmark-openwith-smoke.md
sleep 3
pgrep -fl LeafMark
osascript -e 'tell application "LeafMark" to quit'
```

Observed:

```text
<repo-root>/build/LeafMark.app/Contents/MacOS/LeafMark
```

Result: PASS for launch through macOS open service.

Note:

- This is closer to Finder Open With than passing `--args`.
- It confirms LaunchServices can start LeafMark with a document request.
- Visual confirmation that the document content appeared in the editor still requires manual QA.

### 4. Git artifact hygiene

Command:

```bash
git status --short --ignored
```

Observed:

```text
!! .build/
!! build/
```

Result: PASS

Notes:

- Generated build folders are ignored.
- There were no untracked source/doc files after the self-test report was added.

## Blocked check

### XCTest suite

Command:

```bash
swift test
```

Observed failure:

```text
no such module 'XCTest'
```

Result: BLOCKED by local developer environment.

Resolution if/when desired:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
swift test
```

## Manual QA still required

Before merging this branch into `main`, a human should still verify:

- Welcome document is visible on first launch.
- Editing left pane updates right preview.
- Markdown table/link/list/quote/code/image rendering looks correct.
- Open, Save, Save As work through AppKit panels.
- Save / Don't Save / Cancel appears for New, Open, Finder Open With, and Close.
- Finder Open With loads the selected file content.
- External links open outside the preview.
- Relative local images resolve from the Markdown file directory.
- Copy Rendered pastes rich HTML into a rich-text target and plain text into a plain-text target.

## Decision

Automated and launch-level self-tests available in the current environment passed.

Full QA sign-off is not complete until manual UI QA is performed and, optionally, `swift test` is run in a full Xcode/XCTest environment.
