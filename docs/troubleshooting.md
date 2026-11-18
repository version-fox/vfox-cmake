# Troubleshooting

[中文](zh-CN/troubleshooting.md) | [English](troubleshooting.md)

## `vfox search cmake` is empty

The Available hook reads `assets/version.json` through a jsDelivr mirror of
this repository. Check network access to `fastly.jsdelivr.net`, and make sure
your architecture is one of the [supported ones](platforms.md). A stale local
plugin can be refreshed with `vfox update cmake`.

## `plugin [PreInstall] method error: no version number provided`

This means `PreInstall` could not find a release for the requested version and
your platform. Two known causes, both fixed in the current plugin:

- On ARM Linux (including WSL on ARM), older version data mislabelled `aarch64`
  archives as `386`, so no `arm64` release was ever offered. Run
  `vfox update cmake` to pick up corrected version data.
- vfox 0.6.0 passed the `latest` marker through to `PreInstall` unchanged. The
  plugin now resolves it itself. Upgrading vfox to 1.1.0 or later is also
  recommended.

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

The EnvKeys hook picks the first layout under the given SDK root that contains
a `cmake` executable: `CMake.app/Contents/bin` first, then `bin`. If a link
points at a directory with neither, vfox still adds `bin` to `PATH`, and the
command will not be found. Re-link with the correct root:

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
