# 剪切粘贴实现与 rebase 记录

原实现基于旧 AppDelegate / UserDefaults 架构。rebase 到 `main`（`91e9210`）时完成以下适配：

- [x] 将动作定义迁入 `Shared/RCBase.swift`，保留 main 的默认启用规则。
- [x] 将旧配置补全迁入 `ConfigService`，适配 SwiftData 读取及排序。
- [x] 将文件操作迁入 `Runtime/ActionService.swift`，复用 `PermissionProviding`。
- [x] 为 Finder 粘贴补充当前目录目标；保持剪切仅作用于选中项。
- [x] 使用已解码路径；规范新操作的受保护目录匹配。
- [x] 将独立 `@main` 测试转换为现有测试目标中的 Swift Testing 测试。
- [x] 保留 main 的 Xcode 自动文件同步、签名配置及启动流程。
- [x] 补齐新增界面文本和操作名的本地化。

## 验证命令

```sh
xcodebuild build-for-testing -project RClick.xcodeproj -scheme RClick \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
python3 scripts/check-localization.py
bash -n scripts/build-dmg.sh
git diff --check
```

有可用签名及 App Group 的环境中运行：

```sh
xcodebuild test -project RClick.xcodeproj -scheme RClick -destination 'platform=macOS'
```

Finder 端仍需验收：多选剪切、空白处粘贴、同名文件、授权取消后重试、剪贴板文件复制。DMG 脚本的语法检查不代表已完成签名打包。
