# Changes

[中文](zh-CN/changes.md) | [English](changes.md)

What changed in each release, as a user notices it. GitHub's release pages list the pull requests.

## Unreleased

- `vfox search cmake` and `vfox install` now cover only CMake 3.0 and later, as
  the plugin documents. The version data had listed 2.x releases by mistake, and
  `assets/get_versions.py` no longer collects the 2.x release directories.

## 0.1.8 (2026-11-18)

- Fixed `plugin [PreInstall] method error: no version number provided` on ARM
  Linux, including WSL. The release scraper stored `aarch64` archives under
  the `386` architecture, so no release matched `arm64` and the hook returned
  no version at all. `assets/version.json` now classifies them as `arm64`.
- `PreInstall` now resolves the `latest` marker and an empty version to a
  concrete release (vfox 0.6.0 passed them through unchanged), accepts an
  optional leading `v`, and reports missing versions with a clear error
  instead of returning an empty table. The release catalogue is now replaced
  rather than appended on each refresh, so repeated lookups no longer collect
  duplicates. Added offline tests for all of these cases.
- `vfox link --detect cmake` adopts a CMake that is already on the machine
  instead of downloading another copy: anything on `PATH`, system CMake,
  Homebrew, Scoop, Chocolatey and an explicit `CMAKE_HOME`. Each candidate is
  identified by running `cmake --version`, and installations managed by vfox
  are excluded. See [detect.md](detect.md). This needs vfox 1.1.0 or later,
  which is now the plugin's `minRuntimeVersion`.
- `EnvKeys` discovers the actual `bin` directory of an installed or linked
  CMake instead of assuming the vfox layout, so linked system installs work on
  every platform, including macOS app bundles. It also accepts a `cmake`
  found directly in a directory on `PATH`, which Detect can otherwise offer
  but vfox refuses to link.
- Added offline hook tests for the version comparison, Detect and EnvKeys
  logic, run by `vfox plugin test .` on Linux in CI.
- Added complete English and Chinese documentation, Lua formatting and static
  analysis, license-header checks, GitHub Actions lint/license/test/E2E
  workflows, and Linux and Windows container E2E suites.

## 0.1.7 (2025-09-29)

- Fixed the version scraper and refreshed `assets/version.json`.
- Switched releases to the shared `plugin-manifest-action` workflow.

## 0.1.x (2024-04-14)

- Initial plugin: install official CMake releases on Linux, macOS and Windows,
  with SHA-256 verification and a `PATH` entry from the EnvKeys hook.
