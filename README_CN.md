# vfox-cmake

[![Lint](https://github.com/version-fox/vfox-cmake/actions/workflows/lint.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/lint.yml)
[![License](https://github.com/version-fox/vfox-cmake/actions/workflows/license.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/license.yml)
[![Test](https://github.com/version-fox/vfox-cmake/actions/workflows/test.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/test.yml)
[![E2E](https://github.com/version-fox/vfox-cmake/actions/workflows/e2e.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/e2e.yml)

中文 | [English](README.md)

[vfox](https://vfox.lhan.me/) 的 [CMake](https://cmake.org/) 插件。它可以在
Linux、macOS 和 Windows 上安装 CMake 官方发布版，也能直接接纳本机已有的
CMake。

## 功能

- 安装 3.0 以来的所有官方 CMake 版本，下载后按 SHA-256 校验。
- 自动识别当前平台：Linux（amd64、386、arm64）、macOS（universal / amd64）、
  Windows（amd64、386、arm64）。
- `vfox link --detect cmake` 会找到系统 CMake、Homebrew 或 Scoop 装的版本，
  以及 `PATH` 上的其他版本，直接链接而不重复下载。见[系统 SDK 检测](docs/zh-CN/detect.md)。
- 通过 vfox 的项目版本文件工作（`vfox use`、`.tool-versions`）。
- 每个 PR 都跑离线 hook 单测、Lua 格式化与静态分析、license 头检查，以及
  Linux 和 Windows 容器端到端测试。

## 安装

先安装 [vfox](https://vfox.lhan.me/guide/getting-started.html)，然后：

```bash
vfox add cmake
```

更新插件：

```bash
vfox update cmake
```

## 用法

```bash
# 列出当前平台可用的版本。
vfox search cmake

# 安装某个版本（版本号就是 `cmake --version` 打印的那个）。
vfox install cmake@3.31.6

# 在当前 shell 里选中它。
vfox use cmake@3.31.6

# 或者全局选中。
vfox use --global cmake@3.31.6

# 查看已安装和当前选中的版本。
vfox list cmake
vfox current cmake

# 不改 shell 就用某个版本跑命令。
vfox exec cmake@3.31.6 -- cmake --version
```

本插件需要 vfox **1.1.0** 或更高版本。这是第一个带 Detect hook 的发行版，
`vfox link --detect cmake` 依赖它。

## 文档

- [检测并链接系统 CMake](docs/zh-CN/detect.md)
- [支持的平台与版本](docs/zh-CN/platforms.md)
- [开发与本地检查](docs/zh-CN/development.md)
- [端到端测试](docs/zh-CN/e2e.md)
- [故障排查](docs/zh-CN/troubleshooting.md)
- [变更记录](docs/zh-CN/changes.md)

## 贡献

欢迎提 PR。提交前请按
[docs/zh-CN/development.md](docs/zh-CN/development.md) 跑本地检查；如果改动
用户可见，请同时更新 [docs/changes.md](docs/changes.md) 和
[docs/zh-CN/changes.md](docs/zh-CN/changes.md)。

## 发布

维护者可以在默认分支上从 **Actions → Plugin → Run workflow** 发布，填入不带
`v` 前缀的插件版本即可。共享 workflow 会更新 `metadata.lua`、创建版本提交和
tag，并在本仓库发布 ZIP 与 manifest。不需要本地打 tag，也不需要额外的 release
token。PR 只跑检查；PR 标题不再触发发布。

已有版本 tag 的推送，只要 `PLUGIN.version` 与 tag 一致也支持。发布失败时重新
运行原来失败的 job 即可续跑。

该 workflow 跟随共享的 `@v1` 发布工具版本；升级工具本身不会发布本插件。包契约
和首次上线要求见
[共享 workflow 文档](https://github.com/version-fox/plugin-manifest-action)。

## 许可证

[Apache-2.0](LICENSE)。license 头策略见 [`.licenserc.yaml`](.licenserc.yaml)。
