# LeafMark V1 QA Checklist

日期：2026-06-20

## 目标

这份 checklist 用来验收 LeafMark V1 是否满足“轻量、本地自用的 macOS Markdown 编辑和浏览 App”目标。

V1 验收重点：

- 可以启动本地 macOS App。
- 可以打开、编辑、实时预览、保存、另存为 Markdown / text 文件。
- 可以从 Finder 使用 Open With 打开 `.md`、`.markdown`、`.txt`。
- 常用 Markdown 渲染可用。
- 未保存修改不会被静默丢失。
- Copy Rendered 提供富文本和纯文本 fallback。

## 当前测试环境说明

当前机器 `xcode-select` 指向：

```bash
<CommandLineTools developer directory>
```

当前环境没有完整 Xcode / XCTest runner：

```bash
xcrun --find xctest
# unable to find utility "xctest"
```

因此：

- `swift build` 可以作为编译验证。
- `scripts/build_app_bundle.sh` 可以作为本地 app bundle 验证。
- `swift test` 当前会失败在环境层：`no such module 'XCTest'`。
- 这不代表测试断言失败，也不代表 app 编译失败。

如果以后安装完整 Xcode，可恢复运行：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
swift test
```

## Automated checks

在项目根目录运行：

```bash
cd <repo-root>
```

### 1. Swift package resolution

```bash
swift package resolve
```

Expected:

- 命令 exit code 为 `0`。
- `Package.resolved` 已存在并被 git 跟踪。

### 2. Debug build

```bash
swift build
```

Expected:

- 命令 exit code 为 `0`。
- 输出包含 `Build complete!`。

### 3. App bundle build

```bash
scripts/build_app_bundle.sh
```

Expected:

- 命令 exit code 为 `0`。
- 输出路径：

```bash
<repo-root>/build/LeafMark.app
```

- 生成的 app bundle 存在：

```bash
test -d build/LeafMark.app
```

### 4. Info.plist validation

```bash
plutil -lint Resources/LeafMark.app/Info.plist build/LeafMark.app/Contents/Info.plist
```

Expected:

- 两个 plist 都输出 `OK`。

### 5. Whitespace diff check

```bash
git diff --check
```

Expected:

- 无输出。
- exit code 为 `0`。

### 6. Unit tests

```bash
swift test
```

Expected with full Xcode/XCTest:

- 所有 `LeafMarkCoreTests` 通过。

Expected in current Command Line Tools-only environment:

- 当前会失败，错误类似：

```text
no such module 'XCTest'
```

Status:

- 当前环境：Blocked by missing XCTest.
- 安装完整 Xcode 后：必须重新运行并确认通过。

## Manual QA

先构建并打开 app：

```bash
scripts/build_app_bundle.sh
open build/LeafMark.app
```

### 1. First launch / welcome document

Steps:

1. 启动 LeafMark。
2. 不打开任何文件。
3. 查看左侧编辑区和右侧预览区。

Expected:

- 左侧显示欢迎 Markdown。
- 右侧显示渲染后的欢迎文档。
- 欢迎文档包含标题、列表、引用、链接、表格、代码块、图片语法示例。
- 窗口标题显示 LeafMark。
- Status area 显示保存状态、字数、字符数和路径状态。

### 2. Live preview

Steps:

1. 在左侧编辑区输入：

```markdown
# QA Heading

This is **bold** and *italic*.

- One
- Two
```

2. 等待约 200ms。

Expected:

- 右侧预览自动更新。
- 标题、加粗、斜体、列表渲染正常。
- 没有手动刷新按钮要求。

### 3. Markdown feature rendering

Steps:

1. 新建或编辑文档，粘贴：

````markdown
# Heading

Paragraph with **bold**, *italic*, `inline code`, and [OpenAI](https://openai.com).

> Quote block

1. First
2. Second

- Apple
- Leaf

---

| Feature | Status |
| --- | --- |
| Table | OK |
| Link | OK |

```swift
let name = "LeafMark"
print(name)
```

![Local image](example.png)
````

Expected:

- 标题、段落、加粗、斜体、行内代码、代码块、链接、图片、引用、有序列表、无序列表、分割线、表格均能渲染。
- 图片如果不存在，可以显示 broken image；不应影响编辑、预览或保存。

### 4. New document with unsaved changes

Steps:

1. 修改当前文档。
2. 点击 toolbar 的 `New`。

Expected:

- 弹出 Save / Don't Save / Cancel。
- 选择 `Cancel`：保留当前文档，不新建。
- 选择 `Don't Save`：切换到欢迎文档。
- 选择 `Save`：
  - 如果已有文件路径，保存后新建。
  - 如果没有文件路径，进入 Save As；取消 Save As 时不新建。

### 5. Open `.md`

Steps:

1. 准备一个本地文件：

```bash
cat > /tmp/leafmark-qa.md <<'EOF'
# LeafMark QA

Open markdown test.
EOF
```

2. 在 LeafMark 中点击 `Open`。
3. 选择 `/tmp/leafmark-qa.md`。

Expected:

- 文件内容进入左侧编辑区。
- 右侧预览更新。
- status path 显示当前文件路径。
- 未保存状态清除。

### 6. Open `.markdown` and `.txt`

Steps:

1. 准备文件：

```bash
cat > /tmp/leafmark-qa.markdown <<'EOF'
# Markdown Extension
EOF

cat > /tmp/leafmark-qa.txt <<'EOF'
# Text Extension
EOF
```

2. 分别使用 Open 打开。

Expected:

- `.markdown` 可以打开。
- `.txt` 可以打开。
- 打开后 preview 正常渲染。

### 7. Save existing file

Steps:

1. 打开 `/tmp/leafmark-qa.md`。
2. 修改内容，例如追加：

```markdown

Saved from LeafMark.
```

3. 点击 `Save`。
4. 在终端检查文件：

```bash
grep 'Saved from LeafMark' /tmp/leafmark-qa.md
```

Expected:

- grep 能找到新增内容。
- LeafMark status 显示 Saved。
- 窗口标题不再显示 dirty marker。

### 8. Save As new `.md`

Steps:

1. 新建或编辑未保存文档。
2. 点击 `Save As`。
3. 保存为 `/tmp/leafmark-save-as.md`。

Expected:

- 文件被创建。
- 当前文档路径更新为新路径。
- status 显示 Saved。
- 再点击 Save 会写回同一个文件。

### 9. Close window with unsaved changes

Steps:

1. 修改当前文档但不要保存。
2. 点击窗口关闭按钮。

Expected:

- 弹出 Save / Don't Save / Cancel。
- 选择 `Cancel`：窗口保持打开。
- 选择 `Don't Save`：窗口关闭。
- 选择 `Save`：
  - 保存成功后窗口关闭。
  - Save As 被取消时窗口保持打开。

### 10. Finder Open With

Steps:

1. 运行：

```bash
scripts/build_app_bundle.sh
```

2. 在 Finder 中找到一个 `.md` 文件。
3. 右键选择 Open With，然后选择 `LeafMark.app`。

Expected:

- LeafMark 打开该文件。
- 如果 LeafMark 已打开且当前文档有未保存修改，先弹 Save / Don't Save / Cancel。
- 选择 Cancel 时，不替换当前文档。

### 11. External links

Steps:

1. 在文档中输入：

```markdown
[OpenAI](https://openai.com)
[Email](mailto:test@example.com)
[Local relative](other.md)
```

2. 点击预览中的链接。

Expected:

- `https://openai.com` 使用系统默认浏览器打开。
- `mailto:` 使用系统默认邮件处理方式打开。
- relative/local link 不应让 WebView 离开当前 preview 页面。

### 12. Local image relative path

Steps:

1. 准备目录和图片：

```bash
mkdir -p /tmp/leafmark-images
cp /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns /tmp/leafmark-images/example.icns
cat > /tmp/leafmark-images/image-test.md <<'EOF'
# Image Test

![Example](example.icns)
EOF
```

2. 使用 LeafMark 打开 `/tmp/leafmark-images/image-test.md`。

Expected:

- 图片相对路径按 Markdown 文件所在目录解析。
- 图片不应撑破预览区域。
- 如果该 `.icns` 无法被 WebView 显示，替换成 png/jpg 再测；图片缺失不应影响文档编辑和保存。

### 13. Copy Rendered

Steps:

1. 打开包含标题、列表、链接和表格的文档。
2. 点击 `Copy Rendered`。
3. 粘贴到一个富文本目标，例如 Mail、TextEdit rich text、Word、Notion 或网页编辑器。
4. 再粘贴到纯文本目标，例如 Terminal 或 plain text TextEdit。

Expected:

- 富文本目标尽量保留标题、列表、链接、表格等基础格式。
- 纯文本目标粘贴出可读文本。

## Known limitations for V1

- 当前没有语法高亮。
- 当前没有滚动同步。
- 当前没有多标签页。
- 当前没有复杂主题系统。
- Finder document association 仅面向本机自用 Open With，不做签名、公证、外部分发。
- 当前环境缺少 XCTest，自动化测试需要完整 Xcode 后再跑。

## Post-QA notes and backlog

这个区域用于手动 QA 后继续记录：

- QA 发现的 bug / 遗留问题。
- 使用过程中想到的新功能。
- 暂时不进当前修复批次、但后续值得做的 polish。

记录格式建议：

```text
### YYYY-MM-DD

#### Bugs / regressions

- [ ] [P0/P1/P2] 问题描述
  - Steps:
  - Expected:
  - Actual:
  - Notes:

#### Follow-up features

- [ ] 功能描述
  - Why:
  - Scope:
  - Notes:
```

当前已知后续需求：

- [ ] 生成并接入 LeafMark App icon。
  - 方向：轻量、本地、Markdown、leaf/mark 意象。
  - 需要产出 macOS app icon 所需尺寸，并接入 bundle 的 `Info.plist` / resources。
  - 可先做 1–3 个 icon 方向，确认后再接入。
- [ ] 支持外观模式设置：浅色、深色、跟随系统。
  - 默认建议：跟随系统。
  - UI 可以先放在菜单或 toolbar 附近，保持 V1 简洁。
  - 需要同时影响 SwiftUI 外观和 WKWebView preview CSS。

1. 是需要同步滚动的。
2. Save和Save As两个按钮是有点重复的，放到一起下拉来试试。
3. 右上角的每个按钮的含义文字，需要把默认打开。
4. 左侧，增加目录的展开和关闭。
5. 除了打开单个文件，支持导入整个目录。这样的话可以看到目录下面目录数以及文件的情况，单个都可以去做点击。
6. 需要做多标签，保证打开的文件不会被覆盖，多个标签同时保存，每个标签都可以单独的关闭，或者是关闭其他所有。
7. 支持导出功能，导出的时候不只是导出Markdown文件，还可以选择导出成PDF。
8.

## QA sign-off template

```text
QA date:
Build commit:
Tester:

Automated checks:
- swift package resolve:
- swift build:
- scripts/build_app_bundle.sh:
- plutil:
- git diff --check:
- swift test:

Manual QA:
- First launch:
- Live preview:
- Markdown rendering:
- New unsaved flow:
- Open:
- Save:
- Save As:
- Close unsaved flow:
- Finder Open With:
- External links:
- Local images:
- Copy Rendered:

Known issues:

Decision:
- Pass
- Pass with notes
- Fail
```
