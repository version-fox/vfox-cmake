# 变更记录

[中文](changes.md) | [English](../changes.md)

按发布版本列出用户能感受到的变化。GitHub 的 Release 页面列出了对应的 PR。

## 0.2.0（2026-11-17）

- `vfox link --detect cmake` 会直接采用本机上已有的 CMake，而不再下载一份：
  `PATH` 上的、系统自带的、Homebrew、Scoop、Chocolatey 装的，以及 `CMAKE_HOME`
  指向的。每个候选都会执行 `cmake --version` 来确认版本，vfox 自己管理的安装
  会被排除。见 [detect.md](detect.md)。此功能需要 vfox 1.1.0 或更高版本，
  现在也是插件的 `minRuntimeVersion`。
- `EnvKeys` 会探测已安装或已链接 CMake 真正的 `bin` 目录，而不是假定一定是
  vfox 的目录结构，因此链接的系统版本在每个平台都能用，包括 macOS 的 app
  bundle。
- 新增版本比较、Detect 和 EnvKeys 逻辑的离线 hook 单测，CI 在 Linux 上用
  `vfox plugin test .` 运行。
- 新增完整的中英文文档、Lua 格式化与静态分析、license 头检查、GitHub Actions
  的 lint/license/test/E2E workflow，以及 Linux 和 Windows 容器端到端测试。

## 0.1.7（2025-09-29）

- 修复版本抓取脚本并更新 `assets/version.json`。
- 发布切换到共享的 `plugin-manifest-action` workflow。

## 0.1.x（2024-04-14）

- 初始版本：在 Linux、macOS 和 Windows 上安装 CMake 官方发布版，带 SHA-256
  校验，并由 EnvKeys hook 写入 `PATH`。
