# Detect and link a system CMake

[中文](zh-CN/detect.md) | [English](detect.md)

If CMake is already installed on your machine, vfox can adopt it instead of
downloading another copy. This needs **vfox 1.1.0 or later**.

```bash
# List what the plugin finds and link everything non-interactively.
vfox link --detect cmake --yes

# Without --yes, vfox asks which of the found installations to link.
vfox link --detect cmake
```

The version vfox records is the one `cmake --version` prints, for example
`3.31.6`. After linking, the version behaves like any installed one:

```bash
vfox list cmake
vfox use cmake@3.31.6
vfox exec cmake@3.31.6 -- cmake --version
```

On Windows, vfox 1.1.0's `exec` needs the extension: use
`vfox exec cmake@3.31.6 -- cmake.exe --version`.

Use `vfox link --force cmake@3.31.6 <path>` to point an already linked version
at a different directory. `vfox uninstall cmake@3.31.6` removes a link and
leaves the CMake it points to untouched.

## What is scanned

The Detect hook looks in these places, in order:

- every directory on `PATH`;
- **Linux:** `/usr/local/bin`, `/usr/bin`, `/opt/cmake/bin`, `/opt/bin`,
  `/snap/cmake/current/bin`, `~/.local/bin`;
- **macOS:** `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`,
  `/opt/cmake/bin`, `/Applications/CMake.app/Contents/bin`;
- **Windows:** `Program Files\CMake\bin`, `Program Files (x86)\CMake\bin`,
  `%LOCALAPPDATA%\Programs\CMake\bin`,
  `%USERPROFILE%\scoop\apps\cmake\current\bin`, `C:\ProgramData\chocolatey\bin`,
  `C:\Tools\cmake\bin`;
- `CMAKE_HOME/bin` (and the macOS app-bundle layout under `CMAKE_HOME`) when
  the environment variable is set.

For each candidate the plugin checks for a `cmake` executable (or `cmake.exe`
on Windows), runs `cmake --version`, and uses the version it reports. Results
are deduplicated by version and listed newest first: a release comes before its
release candidates, and a candidate whose release is not installed comes last.
Installations under vfox's own directories are never offered back to you.

## Why linking needs layout detection

A vfox-installed CMake has a `bin/cmake` (or `CMake.app/Contents/bin/cmake`)
under its SDK root. A system CMake keeps the layout it was installed with, for
example `/usr/bin/cmake`. A `cmake` found directly in a directory on `PATH` has
no `bin` level at all. The EnvKeys hook probes all three places and returns the
directory that actually contains the executable, so a linked CMake works the
same as an installed one. See [troubleshooting.md](troubleshooting.md) if a
binary is found but does not run.
