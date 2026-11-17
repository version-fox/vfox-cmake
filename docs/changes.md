# Changes

[中文](zh-CN/changes.md) | [English](changes.md)

What changed in each release, as a user notices it. GitHub's release pages list the pull requests.

## Unreleased

- `vfox link --detect cmake` adopts a CMake that is already on the machine
  instead of downloading another copy: anything on `PATH`, system CMake,
  Homebrew, Scoop, Chocolatey and an explicit `CMAKE_HOME`. Each candidate is
  identified by running `cmake --version`, and installations managed by vfox
  are excluded. See [detect.md](detect.md). This needs vfox 1.1.0 or later,
  which is now the plugin's `minRuntimeVersion`.
- `EnvKeys` discovers the actual `bin` directory of an installed or linked
  CMake instead of assuming the vfox layout, so linked system installs work on
  every platform, including macOS app bundles.
- Added offline hook tests for the version comparison, Detect and EnvKeys
  logic, run by `vfox plugin test .` on Linux in CI.
- Added complete English and Chinese documentation, Lua formatting and static
  analysis, license-header checks, GitHub Actions lint/license/test/E2E
  workflows, and Linux and Windows container E2E suites.

## 0.1.7

- Fixed the version scraper and refreshed `assets/version.json`.
- Switched releases to the shared `plugin-manifest-action` workflow.

## 0.1.x

- Initial plugin: install official CMake releases on Linux, macOS and Windows,
  with SHA-256 verification and a `PATH` entry from the EnvKeys hook.
