# 剪切与粘贴

## 行为

- 剪切仅记录 Finder 选中项，保存在 App Group 的剪切队列中，不立即移动文件。
- 粘贴优先移动剪切队列中的项目；成功项从队列移除，失败项保留以便重试。
- 队列为空时，从系统剪贴板读取文件 URL 并复制。
- 目标为文件夹时粘贴到该文件夹，目标为文件时粘贴到父目录。空白处和无选择的工具栏粘贴使用 Finder 当前目录。
- 同名项目使用数字后缀，例如 `Report 1.pdf`，不覆盖已有文件。

## 当前架构（rebase 到 main 后）

- `Shared/RCBase.swift` 定义操作及本地化显示名称；保留 main 的既有操作默认开关。
- `ActionEntity` 提供新安装默认配置，`ConfigService.load()` 为旧配置补齐缺失操作，保留已有顺序和启用状态，并为补充项分配不冲突的排序值。
- FinderSync 扩展发送现有的签名 `ClickEventPayload`；仅粘贴允许回退到当前目录，剪切仍只使用选中项。
- `ActionService` 执行文件传输，通过 `PermissionProviding` 使用 main 的 Bookmark 授权模型。移动要求源父目录及目标目录的权限；授权取消时保留失败队列。
- `FileMovePlanner` 负责目标解析及重名处理。事件中的 `URL.path` 已解码，不再做百分号解码。
- `RClickApp`、沙盒权限和 IPC 架构沿用 main，不恢复旧的 `PermissiveDir` 或 `Messager`。

## 验证与限制

原独立 Swift 测试迁入 `RClickTests`，覆盖默认配置迁移、目标解析、重名、字面量百分号路径、剪切后移动、取消授权保留队列和剪贴板复制。

主机测试不代替 Finder 交互、沙盒书签授权或签名发布验收。当前剪切队列独立于系统剪贴板；文件传输失败仍仅写日志，尚无界面汇总提示。复制目录到自身或子目录未增加专门的前置检查。
