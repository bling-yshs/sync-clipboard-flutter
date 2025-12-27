<!-- Keep a Changelog guide -> https://keepachangelog.com -->

# SyncClipboard Flutter 更新日志

## [Unreleased]

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

[Unreleased]: https://github.com/bling-yshs/sync-clipboard-flutter/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/bling-yshs/sync-clipboard-flutter/commits/v0.2.1
[0.1.3]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.3
[0.1.2]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.2
[0.1.1]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.1
[0.1.0]: https://github.com/bling-yshs/sync-clipboard-tauri/commits/v0.1.0
