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

local function is_file(path)
    local file = io.open(path, "r")
    if not file then
        return false
    end
    file:close()
    return true
end

--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
--- The bin directory is discovered rather than assumed: vfox-installed CMake
--- lives under `<root>/bin` (or `<root>/CMake.app/Contents/bin` on macOS),
--- while a linked system CMake keeps the layout it was installed with. A
--- binary found directly in a PATH directory has that directory as its root,
--- so the root itself is probed too.
--- @param ctx table Context information; `ctx.path` is the SDK installation directory
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    local candidates = {
        mainPath .. "/CMake.app/Contents/bin",
        mainPath .. "/bin",
        mainPath,
    }
    for _, bin in ipairs(candidates) do
        if is_file(bin .. "/cmake") or is_file(bin .. "/cmake.exe") then
            return {
                {
                    key = "PATH",
                    value = bin,
                },
            }
        end
    end

    local fallback = mainPath .. "/bin"
    if RUNTIME and RUNTIME.osType == "darwin" then
        fallback = mainPath .. "/CMake.app/Contents/bin"
    end
    return {
        {
            key = "PATH",
            value = fallback,
        },
    }
end
