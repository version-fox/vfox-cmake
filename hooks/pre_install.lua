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

local util = require("util")
--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table Context information; `ctx.version` is the user-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local requested = (ctx and ctx.version) or ""

    -- Accept an optional leading "v", often copied from a release tag.
    -- vfox strips it on the ordinary install path, but not for versions
    -- coming from a config file via `vfox install --all`.
    local version = requested:gsub("^v", "")

    -- vfox 0.6.0 passes the "latest" marker (or an empty version) straight
    -- through to PreInstall instead of resolving it from Available first.
    -- Resolve it here so the hook always returns a concrete version: vfox
    -- reports a missing `version` field as "no version number provided".
    -- See https://github.com/version-fox/vfox-cmake/issues/1
    if version == "" or version == "latest" then
        local available = self:Available(ctx)
        assert(#available > 0, "no CMake release available for " .. RUNTIME.osType .. "/" .. RUNTIME.archType)
        version = available[1].version
    elseif #util.RELEASES == 0 then
        self:Available(ctx)
    end

    for _, release in ipairs(util.RELEASES) do
        if release.version == version then
            return release
        end
    end

    -- Never return an empty table: vfox turns that into the misleading
    -- "no version number provided" error. Name the missing version and the
    -- platform instead so the user can act on the failure.
    error("CMake version " .. version .. " is not available for " .. RUNTIME.osType .. "/" .. RUNTIME.archType)
end
