# Development and local checks

[中文](zh-CN/development.md) | [English](development.md)

The plugin is plain Lua 5.1 (the dialect embedded in vfox). Hooks live in
`hooks/`, shared code in `lib/`, offline tests in `tests/`, and the container
E2E suites in `tests/e2e/`.

## Toolchain

- vfox 1.1.0 or later (`vfox plugin test` needs 1.0.13+, the Detect hook needs
  1.1.0);
- Go 1.24 or later, for the E2E suites and the license tools;
- Docker, for the E2E suites and for running the linters in temporary
  containers;
- StyLua 2.5.2 and lua-language-server 3.19.1. The Docker command under
  "Lua formatting" fetches the pinned StyLua for you.

## Offline hook tests

```bash
vfox plugin test .
```

This finds every `tests/**/*_test.lua` and runs each file in a VM of its own.
Each file loads the plugin with `test.load()` from `vfox.test`. That call takes
options such as `os`, `arch`, `env` and `http`, which a test uses to fake the
platform, environment variables and HTTP responses. A file that does not call
`test.load()`, a file that raises an error, and a run that finds no test file
all fail. `io.popen` is disabled in these VMs, so a test that runs a command
replaces it with a Lua stub, as `detect_cmake_test.lua` does. Tests that need
fake files replace `io.open` the same way. No network access is needed.

## Lua formatting

```bash
# Native: install StyLua 2.5.2, then
stylua --check .

# Docker only (no local install needed):
docker run --rm -v "$PWD":/src -w /src debian:bookworm-slim sh -c \
  'apt-get update -qq && apt-get install -y -qq curl unzip && \
   curl -fsSL -o /tmp/stylua.zip https://github.com/JohnnyMorganz/StyLua/releases/download/v2.5.2/stylua-linux-x86_64.zip && \
   unzip -q /tmp/stylua.zip -d /usr/local/bin && stylua --check .'
```

Drop `--check` to apply formatting. The settings are in `stylua.toml`;
`.gitattributes` keeps line endings LF on every platform.

## Lua static analysis

```bash
lua-language-server --check . --checklevel=Warning
```

The globals injected by vfox (`PLUGIN`, `RUNTIME`) are declared in
`.luarc.json`.

## License headers

Every source file (Lua, Python, Go, YAML, TOML, Dockerfile, ignore files)
carries the Apache-2.0 header defined in `.licenserc.yaml`. Check it with:

```bash
go run github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0 header check -c .licenserc.yaml
```

To add missing headers to source files:

```bash
go run github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0 header fix -c .licenserc.yaml
```

Markdown, JSON and `LICENSE` are exempt. The plain-text copy used by
`addlicense` is `.license.tpl`; keep it in sync with the `content` block in
`.licenserc.yaml`.

## Go checks and E2E

```bash
cd tests/e2e
gofmt -l .                 # must print nothing
go vet ./...
go test -short ./...       # skips the container suites

# Full Linux suite (builds an Ubuntu image, installs CMake, tests Detect):
go test -v -timeout 20m -run TestE2E ./linux

# Windows suite: run on a Windows host with Windows container support.
go test -v -timeout 20m -run TestE2E ./windows
```

Both suites create uniquely named containers and remove them on exit. See
[e2e.md](e2e.md) for what each phase asserts and how to run them in CI-like
conditions.

## Version data

`assets/version.json` is generated from the SHA-256 files on cmake.org:

```bash
cd assets
python -m pip install requests beautifulsoup4
python get_versions.py
```

Do not edit the JSON by hand; the `update_versions` workflow regenerates it
weekly.
