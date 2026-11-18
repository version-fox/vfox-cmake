# End-to-end tests

[中文](zh-CN/e2e.md) | [English](e2e.md)

The E2E suites exercise the real plugin with a real vfox inside containers.
They live in `tests/e2e/` and use only the Go standard library plus the
`docker` CLI, so there is no large dependency tree. `go test -short ./...`
skips them; CI runs them in full on every pull request.

## Layout

| Path | Purpose |
| --- | --- |
| `common/` | Pinned versions, Docker helpers, ANSI stripping, assertions |
| `linux/Dockerfile` | Ubuntu 24.04 with a checksum-pinned vfox and the plugin under test |
| `linux/e2e_test.go` | Linux suite |
| `windows/Dockerfile` | Windows Server Core with a checksum-pinned vfox and the plugin under test |
| `windows/e2e_test.go` | Windows suite |

Each Dockerfile installs vfox at build time and copies `metadata.lua`, `hooks`
and `lib` into `$VFOX_HOME/plugin/cmake`. Neither image contains CMake: CMake
may only come from what vfox installs, apart from a stub introduced by the
Detect phase.

## What each suite asserts

Both suites run the same flow against the container:

1. **Setup** — build the image from the repo root and start a long-lived
   container. The container is removed by `t.Cleanup` whatever the outcome.
2. **Plugin** — `vfox --version` is the pinned 1.1.0 and `vfox search cmake`
   lists the pinned release (3.31.6).
3. **Install** — `vfox install cmake@3.31.6` succeeds. The download comes from
   cmake.org, so the test retries five times to absorb a transient network
   failure.
4. **Exec** — `vfox exec cmake@3.31.6 -- cmake --version` prints
   `cmake version 3.31.6` (on Windows, `-- cmake.exe --version`). This proves
   the EnvKeys hook put the right `bin` directory on `PATH`.
5. **Detect** — a CMake-shaped stub reporting 3.20.0 is placed on `PATH`.
   `vfox link --detect cmake --yes` must find it, link it, and the linked
   version must run with `vfox exec`.

On Linux the stub is a shell script in `/opt/fake-cmake/bin`. On Windows the
test compiles a tiny Go program into `cmake.exe` on the host, copies it into
`C:\fake-cmake\bin`, and overrides `PATH` for the `vfox link` call.

## Running locally

```bash
cd tests/e2e
go test -v -timeout 20m -run TestE2E ./linux     # Linux host or Docker Desktop
go test -v -timeout 20m -run TestE2E ./windows   # Windows host, Windows containers
```

The Linux image build and the CMake download need network access. The first
run is the slowest; later runs reuse the downloaded layers.

## CI

`.github/workflows/e2e.yml` runs `e2e-linux` on `ubuntu-latest` and
`e2e-windows` on `windows-latest`. Both set up Go and then run the matching
`go test -v -timeout 40m -run TestE2E ./linux` (or `./windows`). Each runner
only its own suite. A concurrency group cancels superseded pull request runs
while letting every commit on the default branch finish.

The offline hook tests (no containers) run in `.github/workflows/test.yml` with
`vfox plugin test .` on `ubuntu-latest`. There is no macOS CI runner; the
macOS app-bundle layout is covered by the offline `EnvKeys` test instead.
