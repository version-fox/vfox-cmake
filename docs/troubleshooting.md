# Troubleshooting

[中文](zh-CN/troubleshooting.md) | [English](troubleshooting.md)

## `vfox search cmake` is empty

The Available hook reads `assets/version.json` through a jsDelivr mirror of
this repository. Check network access to `fastly.jsdelivr.net`, and make sure
your architecture is one of the [supported ones](platforms.md). A stale local
plugin can be refreshed with `vfox update cmake`.

## `plugin [PreInstall] method error: no version number provided`

Plugin versions before 0.1.8 print this error when they cannot find a release
for the requested version and your platform. Run `vfox update cmake` to get the
current plugin, which names the missing version and platform instead, for
example `CMake version 3.31.6 is not available for linux/arm64`.

This plugin needs vfox 1.1.0 or later (its `minRuntimeVersion`). If you are on an
older vfox, upgrade it first.

If it still happens, run `vfox search cmake` and install one of the listed
versions explicitly, for example `vfox install cmake@3.31.6`.

## `vfox link --detect cmake` finds nothing

The Detect hook looks on `PATH` and in the system locations listed in
[detect.md](detect.md). It needs vfox 1.1.0 or later; check `vfox --version`.
To add an unusual install location, put its `bin` directory on `PATH`, or set
`CMAKE_HOME` to the SDK root and try again. Candidates that are not readable
by the current user are skipped. Installations under vfox's own directories
are intentionally excluded.

## A linked CMake is found but `cmake --version` fails

Detection runs `<binary> --version` to learn the version. If the binary cannot
run (missing dynamic libraries, wrong architecture, broken symlink), it is
skipped. Verify the binary directly:

```bash
/path/to/cmake/bin/cmake --version
```

The EnvKeys hook picks the first location under the given SDK root that
contains a `cmake` executable: `CMake.app/Contents/bin`, then `bin`, then the
root directory itself. If a link points at a directory with none of them, vfox
still adds a `bin` directory to `PATH` (`CMake.app/Contents/bin` on macOS), and
the command will not be found. Re-link with the correct root:

```bash
vfox link --force cmake@3.31.6 /path/to/sdk/root
```

## Checksum error during install

vfox verifies the download against the SHA-256 recorded in
`assets/version.json`. A mismatch means the archive was corrupted in transit
or the file on cmake.org changed. Retry the install; if it keeps failing,
please open an issue with the version and your platform. Never disable the
checksum check as a workaround.

## `stylua --check .` fails

Run `stylua .` to apply the formatting defined in `stylua.toml`, then re-run
the check. Make sure the checkout uses LF line endings (`.gitattributes`
enforces this for new checkouts; an existing CRLF checkout may need
`git add --renormalize .`).

## License check fails

Add the Apache-2.0 header from `.licenserc.yaml` to the offending source file,
or run the `header fix` command in [development.md](development.md). Markdown,
JSON and `LICENSE` do not need a header.
