# vfox-cmake

[![Lint](https://github.com/version-fox/vfox-cmake/actions/workflows/lint.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/lint.yml)
[![License](https://github.com/version-fox/vfox-cmake/actions/workflows/license.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/license.yml)
[![Test](https://github.com/version-fox/vfox-cmake/actions/workflows/test.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/test.yml)
[![E2E](https://github.com/version-fox/vfox-cmake/actions/workflows/e2e.yml/badge.svg)](https://github.com/version-fox/vfox-cmake/actions/workflows/e2e.yml)

[中文](README_CN.md) | English

A [vfox](https://vfox.lhan.me/) plugin for [CMake](https://cmake.org/). It installs
official CMake releases on Linux, macOS and Windows, and can adopt a CMake that
is already on your machine.

## Features

- Installs every official CMake release from 3.0 onwards, with SHA-256
  verification of the downloaded archive.
- Linux (amd64, 386 and arm64), macOS (universal / amd64) and Windows (amd64,
  386 and arm64) builds, selected automatically for the running platform.
- `vfox link --detect cmake` finds a system CMake, a Homebrew or Scoop install,
  or anything else on `PATH`, and links it instead of downloading a second
  copy. See [Detect](docs/detect.md).
- Works with project version files through vfox (`vfox use`, `.tool-versions`).
- Offline hook tests, Lua formatting and static analysis, license-header
  checks, and Linux and Windows container E2E suites on every pull request.

## Install

Install [vfox](https://vfox.lhan.me/guide/getting-started.html) first, then:

```bash
vfox add cmake
```

Updating the plugin:

```bash
vfox update cmake
```

## Usage

```bash
# List the versions available for your platform.
vfox search cmake

# Install a release (the version is the one `cmake --version` prints).
vfox install cmake@3.31.6

# Select it for the current shell.
vfox use cmake@3.31.6

# Or select it globally.
vfox use --global cmake@3.31.6

# See what is installed and what is selected.
vfox list cmake
vfox current cmake

# Run a command with an installed CMake without changing the shell.
vfox exec cmake@3.31.6 -- cmake --version
```

This plugin needs vfox **1.1.0** or later. That is the first release with the
Detect hook used by `vfox link --detect cmake`.

## Documentation

- [Detect and link a system CMake](docs/detect.md)
- [Supported platforms and versions](docs/platforms.md)
- [Development and local checks](docs/development.md)
- [End-to-end tests](docs/e2e.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Changes](docs/changes.md)

## Contributing

Pull requests are welcome. Before opening one, run the local checks described
in [docs/development.md](docs/development.md) and update both
[docs/changes.md](docs/changes.md) and [docs/zh-CN/changes.md](docs/zh-CN/changes.md)
when the change is user-visible.

## Releasing

Maintainers can publish from **Actions → Plugin → Run workflow** on the default
branch by entering a stable plugin version without the `v` prefix. The shared
workflow updates `metadata.lua`, creates the version commit and tag, and
publishes the ZIP and manifest in this repository. No local tag or extra
release token is needed. Pull requests run checks only; PR titles no longer
trigger publication.

Existing version-tag pushes are supported when `PLUGIN.version` already matches
the tag. If publication fails, re-run the original failed job to resume it.

The workflow follows the shared `@v1` release-tool version. Updating the tool
does not release this plugin. See the
[shared workflow documentation](https://github.com/version-fox/plugin-manifest-action)
for the package contract and first-rollout requirements.

## License

[Apache-2.0](LICENSE). See the license header policy in
[`.licenserc.yaml`](.licenserc.yaml).
