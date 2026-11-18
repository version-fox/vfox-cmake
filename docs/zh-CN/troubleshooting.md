# 故障排查

[中文](troubleshooting.md) | [English](../troubleshooting.md)

## `vfox search cmake` 是空的

Available hook 通过本仓库的 jsDelivr 镜像读取 `assets/version.json`。请检查能否
访问 `fastly.jsdelivr.net`，并确认架构在[支持列表](platforms.md)里。本地插件太旧
可以用 `vfox update cmake` 刷新。

## `plugin [PreInstall] method error: no version number provided`

0.1.8 之前的插件在找不到与所请求版本及当前平台匹配的发布包时会报这个错误。执行
`vfox update cmake` 更新到当前插件，它会直接写明缺失的版本和平台，例如
`CMake version 3.31.6 is not available for linux/arm64`。

本插件需要 vfox 1.1.0 或更高版本（即 `minRuntimeVersion`）。如果你用的是更旧的
vfox，请先升级。

如果仍然出现，请先执行 `vfox search cmake`，然后显式安装列出的版本，例如
`vfox install cmake@3.31.6`。

## `vfox link --detect cmake` 什么都没找到

Detect hook 会查 `PATH` 和 [detect.md](detect.md) 里列的系统目录。它需要 vfox
1.1.0 或更高版本，先确认 `vfox --version`。非常规安装位置可以把它 `bin` 目录
放进 `PATH`，或者把 SDK 根目录设到 `CMAKE_HOME` 再试。当前用户读不到的候选会
被跳过；vfox 自己目录里的安装会被有意排除。

## 找到了 CMake，但 `cmake --version` 跑不起来

检测时会执行 `<二进制> --version` 来取得版本号。如果二进制跑不起来（缺动态库、
架构不对、软链坏了），它会被跳过。直接验证一下：

```bash
/path/to/cmake/bin/cmake --version
```

EnvKeys hook 会在给定的 SDK 根目录里按顺序找第一个含 `cmake` 可执行文件的位置：
先 `CMake.app/Contents/bin`，再 `bin`，最后是根目录本身。如果链接指向的目录里
这些位置都没有，vfox 仍会把一个 `bin` 目录加进 `PATH`（macOS 上是
`CMake.app/Contents/bin`），于是命令找不到。用正确的根目录重新链接：

```bash
vfox link --force cmake@3.31.6 /path/to/sdk/root
```

## 安装时报校验和错误

vfox 会按 `assets/version.json` 里的 SHA-256 校验下载文件。不一致说明压缩包在
传输中损坏，或者 cmake.org 上的文件变了。重试安装；如果一直失败，请带上版本和
平台提 issue。不要用关掉校验的办法绕过。

## `stylua --check .` 失败

运行 `stylua .` 按 `stylua.toml` 自动格式化，再重新检查。确认 checkout 用的是
LF 换行（`.gitattributes` 对新 checkout 已强制；已有的 CRLF checkout 可能需要
`git add --renormalize .`）。

## License 检查失败

按 `.licenserc.yaml` 给违规的源文件加上 Apache-2.0 头，或者运行
[development.md](development.md) 里的 `header fix` 命令。Markdown、JSON 和
`LICENSE` 不需要头。
