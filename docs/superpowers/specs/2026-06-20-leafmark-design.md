# LeafMark macOS App 设计文档

日期：2026-06-20

## 1. 概述

LeafMark 是一个轻量、快速、本地优先的 macOS Markdown 编辑和浏览 App，面向个人本机使用。

第一版聚焦最核心的文档闭环：打开 Markdown 文件、编辑 Markdown、实时预览、保存、另存为，以及从 Finder 双击打开 Markdown 文件。

技术路线采用：

- SwiftUI：负责主界面、状态展示和 macOS App 体验。
- 独立 Markdown rendering service：负责把 Markdown 转成 HTML。
- WKWebView preview：负责稳定显示渲染结果，并支持较自然的富文本复制。

第一版不做 App Store 上架、外部分发、签名公证、云同步、账号、协作、插件系统或复杂知识库能力。

## 2. 产品目标

第一版要做到：

- App 名称为 LeafMark。
- 是一个真正的 macOS 本地 App。
- 启动和日常使用保持轻快。
- 使用 SwiftUI 构建主界面。
- 支持本地 Markdown 编辑和实时预览。
- 支持常用 Markdown 语法：标题、段落、加粗、斜体、行内代码、代码块、链接、图片、有序列表、无序列表、引用、分割线、简单表格。
- 支持打开、保存、另存为本地文件。
- 支持从 Finder 双击打开 Markdown 文件。
- 保留未来迁移到 iPhone/iPad 的结构空间，至少让文档状态和 Markdown rendering service 可以复用。

## 3. 第一版不做什么

为了保持第一版轻量，明确不做：

- Electron 或 Tauri 外壳。
- App Store 发布流程。
- 面向外部分发的签名、公证、安装器。
- 云同步。
- 账号系统。
- 多人协作。
- 插件系统。
- 目录树、标签、双链、知识库管理。
- 多标签页。
- 编辑器语法高亮。
- 编辑区和预览区滚动同步。
- 复杂主题系统。
- Markdown 工具按钮栏。

这些能力可以以后再考虑，但不进入第一版。

## 4. 平台与依赖

- 最低系统版本：macOS 14+。
- UI framework：SwiftUI。
- 预览容器：WKWebView。
- Markdown 渲染：引入一个轻量 Swift Package，用于 Markdown to HTML。

Markdown 渲染依赖必须封装在 LeafMark 自己的 “MarkdownRenderService” 后面。这样以后如果要更换渲染库，不需要改 UI 和文档状态代码。

## 5. 页面结构与视觉方向

LeafMark 第一版采用单窗口、双栏布局。

- 左侧：Markdown 编辑区。
- 右侧：Markdown 预览区。
- 默认窗口尺寸：约 1200 × 800。
- 默认左右比例：50% / 50%。
- 中间分隔线可以拖拽调整。
- 视觉风格：原生、安静、低干扰。
- 第一版优先浅色模式。深色模式可以跟随系统基础能力，但不是第一版重点。

整体气质不是专业 IDE，也不是复杂知识库，而是一个打开就能写、写完能看、看完能保存和复制的小工具。

## 6. 首次启动

首次启动或没有打开文件时，LeafMark 显示一份欢迎示例文档。

欢迎文档用于展示 LeafMark 支持的 Markdown 能力，包括标题、列表、引用、链接、表格、代码块和图片语法。

用户开始编辑欢迎文档后，它就变成一个普通未保存文档。用户保存时进入 Save As 流程。

## 7. 主界面

主窗口由三部分组成：

- Toolbar
- 编辑/预览工作区
- Status area

Toolbar 提供常用操作：

- New
- Open
- Save
- Save As
- Toggle Preview
- Copy Rendered

窗口标题显示当前文件名和 App 名称。文档有未保存修改时，标题使用一个简单标记提示，例如前置圆点或星号：”• notes.md — LeafMark”。

Status area 显示：

- 保存状态
- 字数
- 字符数
- 当前文件路径的简短形式

## 8. 编辑体验

编辑区第一版使用原生 SwiftUI text editing 组件。

需要支持标准 macOS 文本行为：

- 输入
- 选择
- 复制
- 粘贴
- Undo
- Redo

第一版不要求：

- 语法高亮
- 自动补全
- Slash commands
- Markdown 格式按钮
- WYSIWYG 编辑

## 9. 预览体验

预览区使用 “WKWebView”。

预览区接收由 “MarkdownRenderService” 生成的完整 HTML，并显示渲染后的 Markdown 内容。

编辑 Markdown 后，预览区实时更新。为了避免每次按键都触发完整渲染，更新需要做 debounce，目标延迟约 150–300ms。

预览 HTML 内置一份轻量 CSS，用于保证基础阅读体验：

- 清晰的标题层级
- 合理的段落间距
- 引用样式
- 行内代码和代码块样式
- 表格边框和单元格间距
- 图片最大宽度限制，避免撑破预览区

## 10. Markdown 渲染

Markdown 渲染由 “MarkdownRenderService” 负责。

它的职责：

- 把 Markdown source 转成 HTML。
- 把 HTML 包装成可直接预览的完整页面。
- 注入基础 CSS。
- 根据当前 Markdown 文件所在目录解析本地图片相对路径。
- 保留链接。
- 支持表格。

“MarkdownRenderService” 接收 Markdown 文本和可选的 base file URL，返回可供 WebView 加载的 HTML。

它不负责保存文件，也不拥有文档状态。

## 11. 富文本复制

LeafMark 需要支持从预览区复制渲染后的内容，并在目标软件支持的情况下尽量保留格式。

第一版选择 WebView 预览，一个重要原因就是 HTML 内容天然更适合放进 pasteboard。复制预览内容时，目标是同时提供富文本/HTML 和纯文本 fallback。

预期效果：

- 粘贴到邮件、Word 类编辑器、Notion 类工具、网页编辑器时，尽量保留标题、加粗、列表、链接、引用和简单表格。
- 粘贴到纯文本 App 时，自动退化成纯文本。
- 复杂表格样式和本地图片在不同目标 App 中表现可能不同，第一版只保证基础可用。

## 12. 打开文件

用户可以在 LeafMark 内打开本地文件。

支持扩展名：

- .md
- .markdown
- .txt

打开文件后：

- 文件内容进入编辑区。
- 当前 file URL 保存到文档状态。
- 当前文件所在目录作为预览区解析本地图片的 base URL。

如果当前文档有未保存修改，打开新文件前需要弹出确认：

- Save
- Don't Save
- Cancel

## 13. 保存

如果当前文档已有 file URL，Save 会把当前 Markdown 文本写回该文件，并清除未保存状态。

如果当前文档没有 file URL，Save 会进入 Save As 流程。

保存失败时，需要显示明确错误，并且不能清除未保存状态。

## 14. 另存为

Save As 使用 macOS 原生保存面板。

保存成功后：

- 当前 Markdown 文本写入新路径。
- 当前 file URL 更新为新路径。
- 未保存状态清除。

默认扩展名使用 .md。

## 15. 未保存状态

LeafMark 需要跟踪当前编辑内容是否不同于上一次保存或打开时的内容。

未保存状态影响：

- 窗口标题标记
- Status area
- New 前确认
- Open 前确认
- 关闭窗口前确认
- Finder 双击打开另一个文件时的确认

所有可能丢失当前修改的操作，都需要先询问用户 Save / Don't Save / Cancel。

## 16. Finder 双击打开

第一版支持基础 Finder double-click opening。

LeafMark 需要声明 Markdown 文档类型，并处理 macOS 传入的 open document event。

如果 App 已经打开且当前文档有未保存修改，则使用同一套未保存确认流程，然后再加载 Finder 传入的文件。

这只要求本机开发和自用可用，不包含面向外部分发的签名、公证或安装器工作。

## 17. 链接和图片

预览区中的外部链接点击后，用系统默认浏览器打开，不在 WebView 内跳转。

本地图片按当前 Markdown 文件所在目录解析相对路径。

图片显示需要限制最大宽度，避免撑破预览区。

如果本地图片不存在或无法访问，第一版可以接受 WebView 默认 broken image 行为，也可以显示简单提示。不能因为图片加载失败影响整个文档编辑和保存。

## 18. 数据流

核心数据流：

1. 用户在编辑区修改 Markdown。
2. “DocumentViewModel” 更新当前 Markdown 文本，并标记未保存状态。
3. debounce 后，调用 “MarkdownRenderService”。
4. “MarkdownRenderService” 把 Markdown 转成完整 HTML。
5. “MarkdownPreviewView” 把 HTML 加载进 “WKWebView”。
6. Save 和 Save As 保存的是 Markdown source，不保存 HTML。

## 19. 主要组件

### LeafMarkApp

SwiftUI App 入口。负责 App-level commands 和 Finder open document event wiring。

### ContentView

主窗口布局。组合 toolbar、编辑区、预览区和 status area。

### DocumentViewModel

负责当前文档状态：

- Markdown 文本
- 上次保存或加载时的 baseline text
- 当前 file URL
- 展示名称
- 未保存状态
- 欢迎文档状态
- 错误状态

它暴露 New、Open、Save、Save As、loadFromFinderOpen 等文档操作。

### MarkdownRenderService

把 Markdown source 转成 preview-ready HTML，并处理本地资源路径。

### MarkdownPreviewView

SwiftUI 对 “WKWebView” 的包装。负责加载 HTML、处理链接导航策略，以及支持从预览区复制富文本内容。

### FileDialogService

封装 macOS 原生 open panel 和 save panel。这样可以避免文件选择逻辑散落在 UI 或 ViewModel 里。

## 20. 错误处理

LeafMark 第一版需要清楚处理这些错误：

- 文件读取失败
- 文本编码无法读取
- 保存失败
- 没有写入权限
- 本地图片缺失或无法访问
- Markdown 渲染失败

错误可以用系统 alert 或 status message 展示。核心要求是不能静默丢失用户内容。

## 21. 验证方式

第一版完成时，需要验证：

- App 可以作为 macOS App 启动。
- 欢迎文档可以显示并实时预览。
- 可以打开 .md、.markdown、.txt。
- 可以编辑 Markdown。
- 可以实时预览标题、列表、引用、链接、表格、代码块和图片语法。
- 可以保存已有文件。
- 可以另存为新的 .md 文件。
- New / Open / Close / Finder open 替换当前文档前，会处理未保存确认。
- Finder 双击 Markdown 文件可以打开到 LeafMark。
- 点击预览区外部链接会打开系统浏览器。
- 本地相对路径图片可以按 Markdown 文件所在目录解析。
- 从预览区复制到至少一个富文本目标时，格式可以基本保留。
- 粘贴到纯文本目标时，有纯文本 fallback。

## 22. 实现原则

第一版实现要保持克制。

不要在核心文档闭环完成前引入通用文档框架、多窗口管理、主题系统、插件系统或复杂编辑器能力。

每个组件保持清楚边界：

- UI 不直接做 Markdown 转换。
- Renderer 不保存文件。
- WebView 不拥有文档状态。
- 文件选择逻辑不散落在多个 View 里。

## 23. 待实现阶段决定

当前没有阻塞第一版设计的产品决策。

Markdown 渲染 Swift Package 可以在 implementation plan 阶段确定。选择标准：

- 支持表格。
- 支持常用 Markdown 语法。
- 支持 macOS 14+。
- 足够轻量。
- 能封装在 “MarkdownRenderService” 后面。

