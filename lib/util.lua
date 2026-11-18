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

local http = require("http")
local json = require("json")
local version_order = require("version_order")

local util = {}

util.__index = util
local utilSingleton = setmetatable({}, util)

utilSingleton.BASE_URL = "https://cmake.org/files/"
utilSingleton.RELEASES = {}

function util:getInfo()
    local result = {}
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/version-fox/vfox-cmake@main/assets/version.json",
    })

    if err ~= nil then
        error("Failed to get information: " .. err)
    end
    if resp.status_code ~= 200 then
        error("Failed to get information: status_code =>" .. resp.status_code)
    end

    local respInfo = json.decode(resp.body)[RUNTIME.osType] or {}
    local releases = {}
    for _, obj in ipairs(respInfo) do
        if obj.arch == "" or obj.arch == RUNTIME.archType then
            table.insert(result, { version = obj.version, note = "" })
            table.insert(releases, { version = obj.version, url = obj.download_url, sha256 = obj.sha256 })
        end
    end
    -- vfox installs the first entry for "latest", so sorting keeps a release first.
    version_order.sort_newest_first(result)
    -- Replace rather than append: Available can be called more than once in a
    -- single install (for example to resolve "latest"), and stale releases
    -- must not accumulate across calls.
    utilSingleton.RELEASES = releases
    return result
end

return utilSingleton
