-- Copyright 2026 Han Li and contributors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--- Finds CMake installations that are already on the machine, for
--- `vfox link --detect cmake`. Each result names the version the same way
--- `cmake --version` prints it (for example `3.31.6`) and points at the SDK
--- root that the EnvKeys hook understands (a directory holding `bin/cmake`,
--- or a macOS bundle holding `CMake.app/Contents/bin/cmake`).
local detect = {}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lower(value)
    return (value or ""):lower()
end

--- Returns the separator for the current platform.
local function sep()
    if RUNTIME and RUNTIME.osType == "windows" then
        return "\\"
    end
    return "/"
end

--- Joins path segments with the platform separator.
function detect.join(left, ...)
    local s = sep()
    local result = left
    for i = 1, select("#", ...) do
        local right = select(i, ...)
        if result:sub(-1) ~= "/" and result:sub(-1) ~= "\\" then
            result = result .. s
        end
        result = result .. right
    end
    return result
end

--- Quotes a command argument for the current platform's shell.
local function shell_quote(value)
    if RUNTIME and RUNTIME.osType == "windows" then
        return '"' .. value:gsub('"', '""') .. '"'
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

--- Returns an environment variable without assuming `os` is complete.
local function env(name)
    if os and os.getenv then
        return os.getenv(name)
    end
    return nil
end

--- Splits a PATH-like string into directories, dropping empty entries.
function detect.path_dirs(value)
    local result = {}
    if type(value) ~= "string" then
        return result
    end
    local pattern = (RUNTIME and RUNTIME.osType == "windows") and "([^;]+)" or "([^:]+)"
    for dir in value:gmatch(pattern) do
        local d = trim(dir)
        if d ~= "" then
            table.insert(result, d)
        end
    end
    return result
end

--- Parses the first line of `cmake --version` output into a version name.
--- Returns nil when the output is not a CMake version banner.
function detect.version_from_output(output)
    if type(output) ~= "string" then
        return nil
    end
    local version = output:match("cmake%s+version%s+([%d][%w%.%-%+]*)")
    if not version then
        return nil
    end
    version = version:gsub("[%s,;]+$", "")
    if version == "" then
        return nil
    end
    return version
end

--- Derives the SDK root from the path of a `cmake` binary. The root is the
--- parent of `bin` for ordinary installs, the parent of `CMake.app` for a
--- macOS bundle, and the binary's own directory when it has no `bin` parent.
function detect.root_from_bin(bin)
    if type(bin) ~= "string" then
        return ""
    end
    local path = bin:gsub("\\", "/")
    local dir = path:match("^(.*)/[^/]+$") or ""
    local app = dir:match("^(.*)/CMake%.app/Contents/bin$")
    if app then
        return app == "" and "/" or app
    end
    local root = dir:match("^(.*)/bin$")
    if root then
        return root == "" and "/" or root
    end
    return dir
end

--- Returns true for paths vfox itself manages, which must never be detected.
function detect.is_vfox_managed(path)
    local p = lower(path or ""):gsub("\\", "/")
    return p:find("/.vfox/", 1, true) ~= nil or p:find("/plugin/cmake", 1, true) ~= nil
end

--- Candidate directories that may hold a `cmake` binary: everything on PATH
--- first, then the install locations of the common package managers and
--- system CMake on each platform, and finally an explicit CMAKE_HOME.
function detect.candidate_bin_dirs()
    local out, seen = {}, {}
    local function add(dir)
        if type(dir) ~= "string" then
            return
        end
        local d = trim(dir):gsub("[/\\]+$", "")
        if d == "" then
            return
        end
        local key = lower(d):gsub("\\", "/")
        if not seen[key] then
            seen[key] = true
            table.insert(out, d)
        end
    end

    for _, dir in ipairs(detect.path_dirs(env("PATH"))) do
        add(dir)
    end

    local home = env("HOME") or env("USERPROFILE") or ""
    if RUNTIME and RUNTIME.osType == "windows" then
        add((env("ProgramFiles") or "C:\\Program Files") .. "\\CMake\\bin")
        add((env("ProgramFiles(x86)") or "") .. "\\CMake\\bin")
        add((env("LOCALAPPDATA") or "") .. "\\Programs\\CMake\\bin")
        add(home .. "\\scoop\\apps\\cmake\\current\\bin")
        add("C:\\ProgramData\\chocolatey\\bin")
        add("C:\\Tools\\cmake\\bin")
    elseif RUNTIME and RUNTIME.osType == "darwin" then
        add("/opt/homebrew/bin")
        add("/usr/local/bin")
        add("/usr/bin")
        add("/opt/cmake/bin")
        add("/Applications/CMake.app/Contents/bin")
    else
        add("/usr/local/bin")
        add("/usr/bin")
        add("/opt/cmake/bin")
        add("/opt/bin")
        add("/snap/cmake/current/bin")
        add(home .. "/.local/bin")
    end

    local cmake_home = env("CMAKE_HOME")
    if cmake_home and trim(cmake_home) ~= "" then
        add(detect.join(cmake_home, "bin"))
        add(detect.join(cmake_home, "CMake.app", "Contents", "bin"))
    end
    return out
end

--- True when value sorts after other in version order.
function detect.compare_versions(value, other)
    local function parts(version)
        local result = {}
        for part in tostring(version):gmatch("%d+") do
            table.insert(result, tonumber(part))
        end
        return result
    end
    local a, b = parts(value), parts(other)
    for i = 1, math.max(#a, #b) do
        local left, right = a[i] or 0, b[i] or 0
        if left ~= right then
            return left > right
        end
    end
    return false
end

--- Returns true when path names a readable file.
local function is_file(path)
    local file = io.open(path, "r")
    if not file then
        return false
    end
    file:close()
    return true
end

--- Asks a CMake binary for its version.
local function version_of(bin)
    local handle = io.popen(shell_quote(bin) .. " --version 2>&1", "r")
    if not handle then
        return nil
    end
    local output = handle:read("*a")
    handle:close()
    return detect.version_from_output(output)
end

local function binary_name(dir)
    if RUNTIME and RUNTIME.osType == "windows" then
        return detect.join(dir, "cmake.exe")
    end
    return detect.join(dir, "cmake")
end

--- Finds every CMake on the machine. Results are sorted newest first and
--- deduplicated by version: vfox links the first match it is offered.
function detect.find_all()
    local out, seen_paths, seen_versions = {}, {}, {}
    for _, dir in ipairs(detect.candidate_bin_dirs()) do
        if not detect.is_vfox_managed(dir) then
            local bin = binary_name(dir)
            if is_file(bin) and not seen_paths[bin] then
                seen_paths[bin] = true
                local version = version_of(bin)
                if version then
                    local root = detect.root_from_bin(bin)
                    if root ~= "" and not detect.is_vfox_managed(root) and not seen_versions[version] then
                        seen_versions[version] = true
                        table.insert(out, { version = version, path = root, note = "found at " .. bin })
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        return detect.compare_versions(a.version, b.version)
    end)
    return out
end

return detect
