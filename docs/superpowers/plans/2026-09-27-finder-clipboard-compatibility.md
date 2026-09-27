# Finder 剪贴板兼容修正

**目标：** RClick 剪切写入系统文件剪贴板，Finder 原生粘贴能复制正确文件，原生“将项目移到这里”能移动。RClick 粘贴保留剪切移动语义。

**结构：** 新增 `FileClipboard` 封装文件 URL 和剪切会话。会话包含路径、随机标记和剪贴板 changeCount，保存在注入的 UserDefaults 中。只有剪贴板标记、代次与 URL 列表均匹配时，RClick 才按剪切移动。其余情况读取当前文件剪贴板并复制。

**约束：** 保留沙盒与 PermissionProviding；不修改 Finder 原生菜单、不增加辅助功能依赖。单测使用独立 NSPasteboard 和 UserDefaults。失败项可重试；操作期间若剪贴板已被替换，不清空或覆盖新内容。

- [x] 先增加 `FileClipboardTests`，覆盖标准文件 URL、旧文本替换、重启恢复、重新复制相同文件、外部内容替换及部分失败。
- [x] 实现 `writeCut(paths:) -> Bool`、`pendingCut() -> CutSession?`、`fileURLs() -> [URL]`、`finishMove(_:failedPaths:)`。通过 `NSPasteboard.writeObjects` 写入 NSURL，避免将文件路径写成普通文本。
- [x] ActionService 注入并调用 FileClipboard；读取剪切会话时不再直接使用未绑定剪贴板的旧路径队列。旧版本队列不作为新剪贴板的移动依据。
- [x] ActionService 测试全部使用独立剪贴板，补充“剪切 A 后在 Finder 复制 B，RClick 粘贴只复制 B”的回归测试。
- [x] 运行失败用例再实现，运行全部主机测试、Xcode build-for-testing、本地化检查及 git diff --check。
- [x] 更新设计说明，构建签名的 RClick Local，保留原安装备份后替换；以临时测试文件验证 Finder 原生粘贴/移动，恢复测试前剪贴板。

## 验证结果

- 新增回归测试先复现旧实现失败；授权期间更换剪贴板的测试同样先失败再修正。全部主机测试：72 项、12 个套件通过。
- Xcode `build-for-testing`、Release 构建、本地化检查、`git diff --check` 和安装包的严格签名验证通过。
- 已安装的 RClick Local 在 Finder 中用临时文件和文件夹完成四条实际操作：RClick 剪切 → Finder 原生粘贴复制；RClick 剪切 → ⌥⌘V 移动；RClick 剪切 → RClick 粘贴移动；Finder 拷贝 → RClick 粘贴复制。源文件保留/移除及目标内容均通过文件系统核对，字面 `%20`、空格、中文文件名正常，没有生成 `.textClipping`。
- 已恢复测试前剪贴板、撤销临时测试目录授权并关闭测试 Finder 窗口。
- Finder 原生移动不会更新本次测试的剪贴板代次或 URL；RClick 不接管 Finder 原生操作，移动后的旧位置仍由文件传输的存在性检查拒绝。文件传输失败的界面汇总仍不在本次修正范围。
