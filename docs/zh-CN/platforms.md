# 支持的平台与版本

[中文](platforms.md) | [English](../platforms.md)

## 平台

| 系统 | 插件识别的架构 | 压缩包 |
| --- | --- | --- |
| Linux | `amd64`、`386`、`arm64` | `.tar.gz` |
| macOS | `amd64`（Intel）和 universal（`""`；Intel 与 Apple Silicon 都可用） | `.tar.gz` |
| Windows | `amd64`、`386`、`arm64` | `.zip` |

插件把 `RUNTIME.osType`、`RUNTIME.archType` 与 `assets/version.json` 匹配；该文件
由 `assets/get_versions.py` 从 <https://cmake.org/files/> 上的 SHA-256 文件生成。
只有当前平台存在对应压缩包时才会列出该版本。

## 版本

包含 2.8.8 以来的官方发布版，以及 CMake 发布的候选版本。列表由
`update_versions` workflow 每周刷新，也可以从 **Actions → update_versions →
Run workflow** 手动重新生成。

2.8.8 之前的版本不列出：cmake.org 没有为它们提供 SHA-256 校验文件，而插件只提供
能用 SHA-256 校验的压缩包。

版本名就是 CMake 自己打印的那个：

```bash
vfox search cmake        # 当前平台的全部版本
vfox install cmake@4.5.0
vfox install cmake@3.31.6
```

预发布版本保留后缀，例如 `4.5.0-rc1`。

## 要求

- vfox 1.1.0 或更高版本（Detect hook）。
- 能访问 `cmake.org`，以及 Available hook 使用的 `assets/version.json`
  jsDelivr 镜像。
