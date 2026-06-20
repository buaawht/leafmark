# LeafMark V0.1.1 Manual QA Checklist

日期：2026-06-20

## 目标

这份 checklist 用来手动验收 LeafMark V0.1.1。建议用临时 QA 文件夹测试，不要直接拿重要文档测试删除、重命名和覆盖保存。

V0.1.1 验收重点：左侧 Files 文件夹目录树、中间 Editor、右侧 Preview / Outline、多 tab、文件/文件夹管理、滚动同步、外观模式、Markdown/PDF 导出，以及 V0.1.0 基础能力回归。

## 测试准备

建议创建临时目录 LeafMark-QA，里面放这些文件：README.md、notes.markdown、plain.txt、ignored.pdf、images/sample.png、nested/child.md。

README.md 建议包含：多级标题、粗体、斜体、inline code、引用、列表、表格、外部链接、本地相对图片，以及足够多的段落用于滚动测试。

## 自动化验证

在项目根目录运行：

- [ ] swift test
- [ ] swift build
- [ ] scripts/build_app_bundle.sh
- [ ] plutil -lint Resources/LeafMark.app/Info.plist build/LeafMark.app/Contents/Info.plist
- [ ] git diff --check

Expected:

- [ ] swift test 通过，当前应为 45 tests / 0 failures。
- [ ] swift build 输出 Build complete。
- [ ] build/LeafMark.app 生成成功。
- [ ] 两个 plist 都输出 OK。
- [ ] git diff --check 无输出。

## 启动 App

运行 scripts/build_app_bundle.sh 后，打开 build/LeafMark.app。

Expected:

- [ ] App 正常启动。
- [ ] 首次无文件时显示欢迎示例文档。
- [ ] 窗口为单窗口布局。
- [ ] Toolbar 默认显示 icon + text。

## 1. 首次启动 / 欢迎文档

Steps:

- [ ] 启动 App。
- [ ] 不打开任何文件。
- [ ] 查看 Editor、Preview、Status area。

Expected:

- [ ] Editor 显示欢迎 Markdown。
- [ ] Preview 显示渲染后的欢迎文档。
- [ ] Status area 显示保存状态、字数、字符数、路径状态。
- [ ] 无崩溃、无空白窗口。

备注：


## 2. 打开单个文档

Steps:

- [ ] 点击 toolbar 的 Open。
- [ ] 选择一个 .md 文件。

Expected:

- [ ] 文件内容进入 Editor。
- [ ] Preview 正确渲染。
- [ ] Tab 显示当前文件名。
- [ ] Status area 显示路径简写。

备注：


## 3. 打开文件夹 / 左侧 Files 目录树

Steps:

- [ ] 点击 Open Folder。
- [ ] 选择 QA 文件夹。
- [ ] 展开/折叠左侧目录树。

Expected:

- [ ] 左侧显示文件夹目录树。
- [ ] .md、.markdown、.txt 显示。
- [ ] unsupported 文件，例如 .pdf，不显示为可编辑文档。
- [ ] 文件夹在文件前面显示。
- [ ] 子文件夹可展开/折叠。

备注：


## 4. 点击文件打开 / 多 tab

Steps:

- [ ] 在左侧 Files 点击 README.md。
- [ ] 再点击 notes.markdown。
- [ ] 再点击 nested/child.md。
- [ ] 切换不同 tab。

Expected:

- [ ] 每个文件打开为独立 tab。
- [ ] 切换 tab 时 Editor / Preview / Status area 都切换到对应文档。
- [ ] 同一个文件重复点击不会创建重复 tab。
- [ ] 各 tab 内容不会互相覆盖。

备注：


## 5. 编辑、dirty 状态、保存

Steps:

- [ ] 修改当前 tab 内容。
- [ ] 观察 tab / window / status 的保存状态。
- [ ] 点击 Save。
- [ ] 重新打开文件确认内容落盘。

Expected:

- [ ] 修改后显示未保存状态。
- [ ] Save 后未保存状态消失。
- [ ] 保存只影响当前 tab。
- [ ] 其他 tab 内容和 dirty 状态不被误改。

备注：


## 6. Save As

Steps:

- [ ] 打开一个未保存或已有文件。
- [ ] 使用 Save 菜单里的 Save As。
- [ ] 保存为新 .md 文件。

Expected:

- [ ] 新文件写入成功。
- [ ] 当前 tab 名称更新为新文件名。
- [ ] 当前 tab 路径更新为新路径。
- [ ] 未保存状态清除。

备注：


## 7. 新建文件

Steps:

- [ ] 在左侧某个文件夹上打开 context menu。
- [ ] 选择 New File。
- [ ] 输入文件名，例如 qa-new-file。

Expected:

- [ ] 自动创建 qa-new-file.md。
- [ ] 左侧文件树刷新并显示新文件。
- [ ] 新文件自动打开为当前 tab。
- [ ] 文件内容为空或可编辑。

备注：


## 8. 新建文件夹

Steps:

- [ ] 在左侧某个文件夹上打开 context menu。
- [ ] 选择 New Folder。
- [ ] 输入文件夹名，例如 QA Folder。

Expected:

- [ ] 文件夹创建成功。
- [ ] 左侧文件树刷新。
- [ ] 新文件夹可展开。

备注：


## 9. 重命名文件

Steps:

- [ ] 打开一个文件为 tab。
- [ ] 在左侧该文件上选择 Rename。
- [ ] 输入新文件名。

Expected:

- [ ] 文件系统中的文件被重命名。
- [ ] 左侧文件树刷新。
- [ ] 已打开 tab 的文件名和路径同步更新。
- [ ] 文档内容不丢失。

备注：


## 10. 重命名文件夹

Steps:

- [ ] 打开该文件夹下的一个文件。
- [ ] 在左侧该文件夹上选择 Rename。
- [ ] 输入新文件夹名。

Expected:

- [ ] 文件夹被重命名。
- [ ] 左侧文件树刷新。
- [ ] 已打开的子文件 tab 路径同步更新。
- [ ] 内容不丢失。

备注：


## 11. 删除文件 / 文件夹

注意：只在临时 QA 文件夹里测试。

Steps:

- [ ] 在左侧选择一个测试文件，执行 Delete / Move to Trash。
- [ ] 确认删除。
- [ ] 在 Finder 的废纸篓中确认文件存在。
- [ ] 对测试文件夹重复一次。

Expected:

- [ ] 删除前有确认弹窗。
- [ ] 删除走 Trash，不是永久删除。
- [ ] 左侧文件树刷新。
- [ ] 如果被删除文件已打开，对应 tab 被关闭或安全处理。
- [ ] 如果有未保存修改，会先询问 Save / Don’t Save / Cancel。

备注：


## 12. Tab 关闭 / 关闭其他

Steps:

- [ ] 打开 3 个文件。
- [ ] 修改其中一个但不保存。
- [ ] 关闭 clean tab。
- [ ] 关闭 dirty tab。
- [ ] 对当前 tab 执行 Close Others。

Expected:

- [ ] clean tab 可直接关闭。
- [ ] dirty tab 关闭前出现 Save / Don’t Save / Cancel。
- [ ] Cancel 会保留 tab。
- [ ] Close Others 只关闭其他可关闭 tab。
- [ ] 当前 tab 保留。

备注：


## 13. Markdown 渲染

Steps:

- [ ] 在 Editor 粘贴包含标题、粗体、斜体、inline code、引用、列表、表格、链接、图片的 Markdown。
- [ ] 观察 Preview。

Expected:

- [ ] 常用 Markdown 正确渲染。
- [ ] 表格正确显示。
- [ ] 本地相对图片按当前 Markdown 文件所在目录解析。
- [ ] 外部链接点击后用系统浏览器打开，不在 app 内跳转。

备注：


## 14. Outline

Steps:

- [ ] 打开包含多级 heading 的文档。
- [ ] 在右侧切换到 Outline。
- [ ] 点击不同 heading。

Expected:

- [ ] Outline 显示当前文档标题层级。
- [ ] heading 缩进能反映层级。
- [ ] 点击 heading 后切换到 Preview。
- [ ] Editor 跳到对应 heading 附近。
- [ ] Preview 跳到对应 heading 附近。

备注：


## 15. Editor → Preview 滚动同步

Steps:

- [ ] 打开长文档。
- [ ] 在 Editor 中向下滚动。
- [ ] 观察 Preview。

Expected:

- [ ] Preview 跟随 Editor 大致滚动到对应百分比位置。
- [ ] 不要求像素级精确。
- [ ] 快速滚动时不崩溃、不明显卡死。

备注：


## 16. 外观模式

Steps:

- [ ] 点击 Appearance 菜单。
- [ ] 切换 Light。
- [ ] 切换 Dark。
- [ ] 切换 System。

Expected:

- [ ] App UI 跟随所选模式变化。
- [ ] Preview CSS 也跟随模式变化。
- [ ] System 模式跟随 macOS 当前外观。

备注：


## 17. Copy Rendered

Steps:

- [ ] 打开一个包含格式的 Markdown 文档。
- [ ] 点击 Copy Rendered。
- [ ] 粘贴到支持富文本的 App，例如 Notes / Pages / Mail。
- [ ] 再粘贴到纯文本编辑器。

Expected:

- [ ] 富文本 App 中保留基本格式。
- [ ] 纯文本编辑器中有可读文本 fallback。

备注：


## 18. Export Markdown

Steps:

- [ ] 打开一个文档。
- [ ] 点击 Export → Markdown。
- [ ] 保存到 QA 输出目录。
- [ ] 用文本编辑器打开导出的 .md。

Expected:

- [ ] 文件导出成功。
- [ ] 内容与当前 Editor 内容一致。
- [ ] 导出不会改变当前 tab 的保存路径。
- [ ] 导出不会错误清除当前 tab 的 dirty 状态。

备注：


## 19. Export PDF

Steps:

- [ ] 打开一个包含标题、表格、图片、长内容的文档。
- [ ] 点击 Export → PDF。
- [ ] 保存到 QA 输出目录。
- [ ] 打开导出的 PDF。

Expected:

- [ ] PDF 文件生成成功。
- [ ] PDF 内容来自 Preview 渲染结果。
- [ ] 长文档不是只导出当前可视区域。
- [ ] 表格、链接文本、图片显示可接受。

备注：


## 20. Finder / Open With

Steps:

- [ ] 在 Finder 中选择 .md 文件。
- [ ] 使用 Open With 打开 LeafMark。
- [ ] 对 .markdown 和 .txt 重复测试。

Expected:

- [ ] App 启动或切到前台。
- [ ] 文件打开为 tab。
- [ ] 内容正确显示。

备注：


## 21. Window close / unsaved changes

Steps:

- [ ] 打开多个 tab。
- [ ] 修改至少一个 tab 不保存。
- [ ] 关闭窗口。

Expected:

- [ ] App 逐个处理未保存 tab。
- [ ] Save / Don’t Save / Cancel 行为正确。
- [ ] Cancel 会阻止关闭窗口。

备注：


## 22. 隐私 / 本地信息检查

发布或 push 前运行：

- [ ] git grep -n -E '(/Users/|buaawht_home)' -- . || true
- [ ] git grep -n -E '(API[_-]?KEY|api[_-]?key|SECRET|secret|TOKEN|token|\.env)' -- . || true

Expected:

- [ ] 不应出现本机绝对路径。
- [ ] 不应出现 .env、API key、token、secret。
- [ ] 如果命中普通变量名，例如代码里的 token，需要人工确认不是凭证。

备注：


## QA 结论

测试人：

测试日期：

总体结论：

- [ ] 通过，可以准备 push / merge
- [ ] 有阻塞问题，需要修复后重测
- [ ] 有非阻塞问题，可以记录到后续版本

阻塞问题：


非阻塞问题 / 后续需求：

