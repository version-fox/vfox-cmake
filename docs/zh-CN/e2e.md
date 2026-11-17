# 端到端测试

[中文](e2e.md) | [English](../e2e.md)

E2E 测试在容器里用真实的 vfox 跑真实的插件。它们位于 `tests/e2e/`，只依赖 Go
标准库和 `docker` CLI，没有庞大的依赖树。`go test -short ./...` 会跳过它们；CI
在每个 PR 上完整运行。

## 目录结构

| 路径 | 用途 |
| --- | --- |
| `common/` | 固定版本号、Docker 辅助函数、ANSI 剥离、断言 |
| `linux/Dockerfile` | Ubuntu 24.04，内置校验过的 vfox 和待测插件 |
| `linux/e2e_test.go` | Linux 测试 |
| `windows/Dockerfile` | Windows Server Core，内置校验过的 vfox 和待测插件 |
| `windows/e2e_test.go` | Windows 测试 |

每个 Dockerfile 在构建时安装 vfox，并把 `metadata.lua`、`hooks` 和 `lib` 拷到
`$VFOX_HOME/plugin/cmake`。两个镜像都不含 CMake：除了 Detect 阶段引入的 stub，
CMake 只能由 vfox 安装。

## 各套件的断言

两个套件对容器执行同样的流程：

1. **准备** — 从仓库根目录构建镜像，启动一个长期运行的容器。无论结果如何，
   `t.Cleanup` 都会删除容器。
2. **插件** — `vfox --version` 是固定的 1.1.0，`vfox search cmake` 列出固定版本
   3.31.6。
3. **安装** — `vfox install cmake@3.31.6` 成功。下载来自 cmake.org，所以测试
   重试三次，以吸收短暂的网络故障。
4. **执行** — `vfox exec cmake@3.31.6 -- cmake --version` 打印
   `cmake version 3.31.6`。这证明 EnvKeys hook 把正确的 `bin` 目录放进了
   `PATH`。
5. **检测** — 把一个报告 3.20.0 的 CMake 形状 stub 放进 `PATH`。
   `vfox link --detect cmake --yes` 必须找到它、链接它，链接后的版本还要能用
   `vfox exec` 跑起来。

Linux 上的 stub 是 `/opt/fake-cmake/bin` 里的 shell 脚本。Windows 上，测试在
宿主机把一个很小的 Go 程序编译成 `cmake.exe`，拷进 `C:\fake-cmake\bin`，并在
`vfox link` 调用时覆盖 `PATH`。

## 本地运行

```bash
cd tests/e2e
go test -v -timeout 20m -run TestE2E ./linux     # Linux 主机或 Docker Desktop
go test -v -timeout 20m -run TestE2E ./windows   # Windows 主机，Windows 容器
```

镜像构建和 CMake 下载需要网络。第一次最慢；后续运行会复用已下载的层。

## CI

`.github/workflows/e2e.yml` 在 `ubuntu-latest` 上跑 `e2e-linux`，在
`windows-latest` 上跑 `e2e-windows`。两者都装好 Go，然后运行对应的
`go test -v -run TestE2E ./...`。并发组会取消被新提交取代的 PR 运行，但让默认
分支上的每个提交都跑完。

不使用容器的 hook 测试在 `.github/workflows/test.yml` 里，它还用 vfox 的 Lua
解释器跑 macOS 文件系统布局检查。
