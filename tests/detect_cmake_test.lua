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

local test = require("vfox.test")
test.load({
    os = "linux",
    arch = "amd64",
    env = {
        PATH = "/usr/bin:/opt/cmake/bin:/usr/local/bin:/home/test/.vfox/versions/cmake/bin",
        HOME = "/home/test",
    },
})
local detect = require("detect_cmake")

local cases = 0

local function norm(path)
    return (path:gsub("\\", "/"))
end

-- Fake filesystem and version banners; io.popen reports the output keyed by
-- the binary its command quotes, just as a real CMake would.
local files = {}
local banners = {}

io.open = function(path, mode)
    if mode == "r" then
        local content = files[norm(path)]
        if content == nil then
            return nil
        end
        return {
            read = function(_, pattern)
                if pattern == "*a" then
                    return content
                end
                return nil
            end,
            close = function()
                return true
            end,
        }
    end
    return nil
end

io.popen = function(cmd, mode)
    local bin = cmd:match("'([^']+)'") or cmd:match('"([^"]+)"')
    local output = banners[bin] or ""
    return {
        read = function(_, pattern)
            if pattern == "*a" then
                return output
            end
            return nil
        end,
        close = function()
            return true
        end,
    }
end

local function check(condition, message)
    assert(condition, message)
    cases = cases + 1
end

check(detect.version_from_output("cmake version 3.31.6\nCMake suite\n") == "3.31.6", "plain version banner")
check(detect.version_from_output("cmake version 4.0.0-rc1") == "4.0.0-rc1", "pre-release version")
check(detect.version_from_output("cmake version 3.28.1\n") == "3.28.1", "trailing newline")
check(detect.version_from_output("/usr/bin/cmake: command not found") == nil, "unrelated output")
check(detect.version_from_output(nil) == nil, "no output")

check(detect.root_from_bin("/usr/bin/cmake") == "/usr", "system root")
check(detect.root_from_bin("/opt/cmake/bin/cmake") == "/opt/cmake", "prefix root")
check(detect.root_from_bin("/Applications/CMake.app/Contents/bin/cmake") == "/Applications", "macOS bundle")
check(detect.root_from_bin("C:\\Program Files\\CMake\\bin\\cmake.exe") == "C:/Program Files/CMake", "Windows root")

check(detect.compare_versions("3.31.6", "3.28.1"), "newer version sorts first")
check(not detect.compare_versions("3.28.1", "3.31.6"), "older version does not sort first")
check(not detect.compare_versions("3.31.6", "3.31.6"), "equal versions")

local dirs = detect.path_dirs("/usr/bin::/opt/cmake/bin:")
check(#dirs == 2 and dirs[1] == "/usr/bin" and dirs[2] == "/opt/cmake/bin", "PATH splitting")

files["/usr/bin/cmake"] = ""
files["/opt/cmake/bin/cmake"] = ""
files["/usr/local/bin/cmake"] = ""
files["/home/test/.vfox/versions/cmake/bin/cmake"] = ""
banners["/usr/bin/cmake"] = "cmake version 3.28.1\n"
banners["/opt/cmake/bin/cmake"] = "cmake version 3.31.6\n"
banners["/usr/local/bin/cmake"] = "cmake version 3.31.6\n"
banners["/home/test/.vfox/versions/cmake/bin/cmake"] = "cmake version 9.9.9\n"

local found = detect.find_all()
check(#found == 2, "two distinct versions (got " .. #found .. ")")
check(found[1].version == "3.31.6" and found[2].version == "3.28.1", "newest first")
check(found[1].path == "/opt/cmake", "root of the first match")
check(found[1].note ~= "" and found[2].note ~= "", "entries carry a note")

print(("PASS %d detect_cmake checks"):format(cases))
