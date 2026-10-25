<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# SyncClipboard Flutter 更新日志
## [Unreleased]
## [0.3.4] - 2026-07-09

### Fixed

- 修复通过分享到 app 的方式，上传大于 100 MB 文件，无法正常上传的问题 （修改了上传实现，可能引入新的 bug...）

## [0.3.3] - 2026-04-14

### ⚠ 重要提醒
- 0.3.0 以后版本，仅能与 SyncClipboard v3.1.1 及以上版本搭配使用

### Feat

- 记忆日志级别筛选并优化日志页展示

### Fixed

- 修复部分文本无法正常读取上传的问题

## [0.3.2] - 2026-04-06

### ⚠ 重要提醒
- 0.3.0 以后版本，仅能与 SyncClipboard v3.1.1 及以上版本搭配使用

### Added

- 支持直接上传剪贴板的图片/文件等

### Fixed

- 导航键模式下 UI 被遮挡
- 点击空白处自动移除输入框的焦点
- 磁贴有概率变暗无法交互

## [0.3.1] - 2026-03-21

### ⚠ 重要提醒
- 0.3.0 以后版本，仅能与 SyncClipboard v3.1.1 及以上版本搭配使用

### Added

- 设置页新增日志查看页面
- 支持自定义下载目录
- 支持根据当前 Wi-Fi 名称自动切换服务器配置

### Fixed

- 修复输入密码时输入框被键盘遮挡

### Changed

- 调整首页服务器配置选项卡样式

## [0.3.0] - 2026-02-07

### Changed

- ⚠ 破坏性更新
- 适配新版本 SyncClipboard，仅能与 v3.1.1 及以上版本搭配使用

## [0.2.3] - 2026-01-05

### Added

- 支持多服务器配置切换
- 文件上传时添加 MD5 校验，从而符合 API 规范

## [0.2.2] - 2025-12-27

### Added

- 添加更新检查
- 支持在调试页面手动上传文件

### Fixed

- 替换底部导航栏诡异的原生动画

## [0.2.1] - 2025-12-07

### Added

- 使用 Flutter 重写
- 支持分享文本或任意文件到 app

## [0.2.0] - 2025-11-30

### Added

- 支持图片通过安卓原生分享功能分享到此app，自动上传图片到服务器

## [0.1.2] - 2025-10-30

### Fixed

- 应用启动时，有概率上传剪贴板失败

- WebDAV 不存在 SyncClipboard.json 时 404 报错，改为不存在 json 时自动创建一个

## [0.1.1] - 2025-10-18

### Added

- 文件上传支持多选

### Fixed

- 修复退出 app 后，多任务页面残留

## [0.1.0] - 2025-10-05

### Added

- 第一次正式发布 sync-clipboard-tauri

[Unreleased]: https://github.com/bling-yshs/sync-clipboard-flutter/compare/v0.3.4...HEAD
[0.3.4]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.3.4
[0.3.3]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.3.3
[0.3.2]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.3.2
[0.3.1]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.3.1
[0.3.0]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.3.0
[0.2.3]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.2.3
[0.2.2]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.2.2
[0.2.1]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.2.1
[0.1.3]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.3
[0.1.2]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.2
[0.1.1]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.1
[0.1.0]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.0
