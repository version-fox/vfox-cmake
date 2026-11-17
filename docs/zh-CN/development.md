# 开发与本地检查

[中文](development.md) | [English](../development.md)

插件是纯 Lua 5.1（vfox 内置的那个方言）。hook 在 `hooks/`，公共代码在 `lib/`，
离线测试在 `tests/`，容器端到端测试在 `tests/e2e/`。

## 工具链

- vfox 1.1.0 或更高版本（`vfox plugin test` 需要 1.0.13+，Detect hook 需要 1.1.0）；
- Go 1.24 或更高版本，用于 E2E 测试和 license 工具；
- Docker，用于 E2E 测试，以及在临时容器里跑检查；
- StyLua 2.5.2 和 lua-language-server 3.19.1（也可以用下面的 Docker 命令，它会
  下载固定版本）。

## 离线 hook 测试

```bash
vfox plugin test .
```

它会找到每个 `tests/**/*_test.lua`，在独立的 VM 里运行，并 mock 掉 `io.open`、
`io.popen` 和 HTTP；插件报错即失败，不需要网络。

## Lua 格式化

```bash
# 本地装了 StyLua 2.5.2 时：
stylua --check .

# 只用 Docker（无需本地安装）：
docker run --rm -v "$PWD":/src -w /src debian:bookworm-slim sh -c \
  'apt-get update -qq && apt-get install -y -qq curl unzip && \
   curl -fsSL -o /tmp/stylua.zip https://github.com/JohnnyMorganz/StyLua/releases/download/v2.5.2/stylua-linux-x86_64.zip && \
   unzip -q /tmp/stylua.zip -d /usr/local/bin && stylua --check .'
```

去掉 `--check` 即为自动格式化。配置在 `stylua.toml`；`.gitattributes` 保证所有
平台都用 LF 换行。

## Lua 静态分析

```bash
lua-language-server --check . --checklevel=Warning
```

vfox 注入的全局变量（`PLUGIN`、`RUNTIME`）在 `.luarc.json` 里声明。

## License 头

每个源文件（Lua、Python、Go、YAML、TOML、Dockerfile、ignore 文件）都要带
`.licenserc.yaml` 里定义的 Apache-2.0 头。检查：

```bash
go run github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0 header check -c .licenserc.yaml
```

自动补头：

```bash
go run github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0 header fix -c .licenserc.yaml
```

Markdown、JSON 和 `LICENSE` 免检。`addlicense` 用的纯文本模板是
`.license.tpl`；改动时要和 `.licenserc.yaml` 里的 `content` 保持一致。

## Go 检查与 E2E

```bash
cd tests/e2e
gofmt -l .                 # 必须没有输出
go vet ./...
go test -short ./...       # 跳过容器测试

# 完整 Linux 测试（构建 Ubuntu 镜像、安装 CMake、测试 Detect）：
go test -v -timeout 20m -run TestE2E ./linux

# Windows 测试：在支持 Windows 容器的 Windows 主机上运行。
go test -v -timeout 20m -run TestE2E ./windows
```

两个测试都会创建带唯一名字的容器，并在退出时清理。每个阶段断言什么、怎样模拟
CI 环境，见 [e2e.md](e2e.md)。

## 版本数据

`assets/version.json` 从 cmake.org 上的 SHA-256 文件生成：

```bash
cd assets
python -m pip install requests beautifulsoup4
python get_versions.py
```

不要手改这个 JSON；`update_versions` workflow 每周重新生成一次。
