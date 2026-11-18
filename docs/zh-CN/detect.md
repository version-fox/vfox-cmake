# 检测并链接系统 CMake

[中文](detect.md) | [English](../detect.md)

如果机器上已经装了 CMake，vfox 可以直接接纳它，而不用再下载一份。此功能需要
**vfox 1.1.0 或更高版本**。

```bash
# 列出插件找到的安装并全部链接（不交互）。
vfox link --detect cmake --yes

# 不加 --yes 时，vfox 会让你选择要链接哪一个。
vfox link --detect cmake
```

vfox 记录的版本号就是 `cmake --version` 打印的那个，例如 `3.31.6`。链接之后，
它和普通安装的版本用法一样：

```bash
vfox list cmake
vfox use cmake@3.31.6
vfox exec cmake@3.31.6 -- cmake --version
```

Windows 上 vfox 1.1.0 的 `exec` 需要带扩展名：用
`vfox exec cmake@3.31.6 -- cmake.exe --version`。

已经链接过的版本可以用 `vfox link --force cmake@3.31.6 <路径>` 改指向别的
目录；`vfox unlink cmake@3.31.6` 删除链接。

## 扫描范围

Detect hook 按以下顺序查找：

- `PATH` 上的所有目录；
- **Linux：** `/usr/local/bin`、`/usr/bin`、`/opt/cmake/bin`、`/opt/bin`、
  `/snap/cmake/current/bin`、`~/.local/bin`；
- **macOS：** `/opt/homebrew/bin`、`/usr/local/bin`、`/usr/bin`、
  `/opt/cmake/bin`、`/Applications/CMake.app/Contents/bin`；
- **Windows：** `Program Files\CMake\bin`、`Program Files (x86)\CMake\bin`、
  `%LOCALAPPDATA%\Programs\CMake\bin`、
  `%USERPROFILE%\scoop\apps\cmake\current\bin`、`C:\ProgramData\chocolatey\bin`、
  `C:\Tools\cmake\bin`；
- 设置了 `CMAKE_HOME` 时，扫描 `CMAKE_HOME/bin`（以及 macOS app bundle 的目录
  结构）。

对每个候选，插件检查是否存在 `cmake` 可执行文件（Windows 上是 `cmake.exe`），
运行 `cmake --version`，并用它报告的版本命名。结果按版本去重（最新的在前），
vfox 自己目录里的安装不会被提供给你。

## 为什么链接需要探测目录结构

vfox 安装的 CMake，SDK 根目录下面是 `bin/cmake`（macOS 上是
`CMake.app/Contents/bin/cmake`）；系统 CMake 则保持它原来的布局，比如
`/usr/bin/cmake`；直接放在 `PATH` 某目录里的 `cmake` 则没有 `bin` 这一层。
EnvKeys hook 会依次探测这三个位置，返回真正包含可执行文件的目录，因此链接的
CMake 和安装的用起来一样。如果找到了二进制却跑不起来，见
[故障排查](troubleshooting.md)。
