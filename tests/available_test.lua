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

--- Builds a version.json body for linux amd64 with one entry per version.
local function catalogue(versions)
    local entries = {}
    for i, version in ipairs(versions) do
        entries[i] = string.format(
            '{"arch":"amd64","version":"%s","download_url":"https://example.com/cmake-%s-linux-x86_64.tar.gz","sha256":"%s"}',
            version,
            version,
            version
        )
    end
    return '{"darwin": [], "windows": [], "linux": [' .. table.concat(entries, ",") .. "]}"
end

-- The current body is read at call time, so a test can swap the catalogue.
local current = catalogue({ "4.5.0-rc2", "4.4.5", "4.5.0-rc3", "4.5.0", "4.5.0-rc1" })

local plugin = test.load({
    os = "linux",
    arch = "amd64",
    http = function(request)
        assert(request.method == "GET")
        return { status_code = 200, body = current }
    end,
})

local cases = 0
local function check(condition, message)
    assert(condition, message)
    cases = cases + 1
end

local function listed()
    local versions = {}
    for i, item in ipairs(plugin:Available({})) do
        versions[i] = item.version
    end
    return table.concat(versions, " ")
end

-- Releases come first and each candidate sits below its release. vfox takes
-- the first entry as `latest`, so `latest` must be the release.
local order = listed()
check(order == "4.5.0 4.5.0-rc3 4.5.0-rc2 4.5.0-rc1 4.4.5", "newest first (got " .. order .. ")")

local info = plugin:PreInstall({ version = "latest" })
check(info.version == "4.5.0", "latest is the release (got " .. tostring(info.version) .. ")")
check(info.url == "https://example.com/cmake-4.5.0-linux-x86_64.tar.gz", "latest carries the release URL")
check(info.sha256 == "4.5.0", "latest carries the release checksum")

info = plugin:PreInstall({ version = "4.5.0-rc3" })
check(info.version == "4.5.0-rc3", "release candidate resolves by name")
check(info.url == "https://example.com/cmake-4.5.0-rc3-linux-x86_64.tar.gz", "release candidate carries its URL")

-- 4.6.0 has candidates but no release yet. Its candidate is listed last, so
-- `latest` stays on 4.5.0, and it can still be installed by name.
current = catalogue({ "4.6.0-rc1", "4.5.0", "4.5.0-rc1" })
order = listed()
check(order == "4.5.0 4.5.0-rc1 4.6.0-rc1", "unreleased candidate listed last (got " .. order .. ")")

info = plugin:PreInstall({ version = "latest" })
check(info.version == "4.5.0", "latest skips an unreleased candidate (got " .. tostring(info.version) .. ")")

info = plugin:PreInstall({ version = "4.6.0-rc1" })
check(info.version == "4.6.0-rc1", "unreleased candidate installs by name")

-- A platform whose list has nothing but candidates: `latest` is the newest one.
current = catalogue({ "4.6.0-rc1", "4.6.0-rc2" })
order = listed()
check(order == "4.6.0-rc2 4.6.0-rc1", "candidates only, newest first (got " .. order .. ")")

info = plugin:PreInstall({ version = "latest" })
check(
    info.version == "4.6.0-rc2",
    "latest is the newest candidate when there is no release (got " .. tostring(info.version) .. ")"
)

print(("PASS %d available checks"):format(cases))
