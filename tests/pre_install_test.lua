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

-- Small version catalogue with both x86_64 and aarch64 Linux releases. Both
-- are needed: the missing aarch64 mapping used to leave ARM (including WSL)
-- users with no releases at all, which surfaced as "no version number
-- provided" from PreInstall.
local body = [[
{
    "darwin": [],
    "windows": [],
    "linux": [
        {"arch":"amd64","version":"3.30.0","download_url":"https://example.com/cmake-3.30.0-linux-x86_64.tar.gz","sha256":"amd64-330"},
        {"arch":"amd64","version":"3.31.6","download_url":"https://example.com/cmake-3.31.6-linux-x86_64.tar.gz","sha256":"amd64-3316"},
        {"arch":"arm64","version":"3.30.0","download_url":"https://example.com/cmake-3.30.0-linux-aarch64.tar.gz","sha256":"arm64-330"},
        {"arch":"arm64","version":"3.31.6","download_url":"https://example.com/cmake-3.31.6-linux-aarch64.tar.gz","sha256":"arm64-3316"}
    ]
}
]]

local requests = 0
local plugin = test.load({
    os = "linux",
    arch = "amd64",
    http = function(request)
        requests = requests + 1
        assert(request.method == "GET")
        assert(request.url == "https://fastly.jsdelivr.net/gh/version-fox/vfox-cmake@main/assets/version.json")
        return { status_code = 200, body = body }
    end,
})

local cases = 0
local function check(condition, message)
    assert(condition, message)
    cases = cases + 1
end

-- An explicit version still resolves to the matching download.
local info = plugin:PreInstall({ version = "3.30.0" })
check(info.version == "3.30.0", "explicit version")
check(info.url == "https://example.com/cmake-3.30.0-linux-x86_64.tar.gz", "explicit version URL")
check(info.sha256 == "amd64-330", "explicit version checksum")

-- vfox 0.6.0 passes "latest" through to PreInstall. It must resolve to a
-- concrete version instead of returning {} (version-fox/vfox-cmake#1).
info = plugin:PreInstall({ version = "latest" })
check(info.version == "3.31.6", "latest resolves to newest available version")
check(info.url == "https://example.com/cmake-3.31.6-linux-x86_64.tar.gz", "latest carries a real URL")

-- An empty version behaves like "latest" and must never produce an empty result.
info = plugin:PreInstall({ version = "" })
check(info.version == "3.31.6", "empty version behaves like latest")

-- A leading "v" is tolerated (users copy it from CMake release tags).
info = plugin:PreInstall({ version = "v3.30.0" })
check(info.version == "3.30.0", "v prefix is accepted")

-- An unknown version must fail loudly instead of returning a table without a
-- version, which is what triggered the reported error.
local ok, err = pcall(function()
    return plugin:PreInstall({ version = "9.9.9" })
end)
check(not ok, "unknown version fails instead of returning an empty table")
check(tostring(err):find("9.9.9", 1, true) ~= nil, "error names the missing version")

-- Resolving "latest" refreshes the release list; repeated calls must not
-- accumulate duplicate entries in the cached list.
local util = require("util")
local before = #util.RELEASES
plugin:PreInstall({ version = "latest" })
check(#util.RELEASES == before, "repeated lookups do not duplicate releases")

-- ARM Linux (including WSL on ARM) must see the aarch64 releases.
RUNTIME.archType = "arm64"
util.RELEASES = {}
info = plugin:PreInstall({ version = "3.30.0" })
check(info.version == "3.30.0", "arm64 version resolves")
check(info.url == "https://example.com/cmake-3.30.0-linux-aarch64.tar.gz", "arm64 gets the aarch64 archive")

print(("PASS %d pre_install checks"):format(cases))
