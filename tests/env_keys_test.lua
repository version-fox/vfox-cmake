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
test.load()
local files = {}
local cases = 0

io.open = function(path, mode)
    if mode == "r" and files[path] then
        return {
            read = function()
                return ""
            end,
            close = function()
                return true
            end,
        }
    end
    return nil
end

local function keys(path)
    return PLUGIN:EnvKeys({ path = path })
end

files["/opt/cmake/bin/cmake"] = true
assert(keys("/opt/cmake")[1].value == "/opt/cmake/bin", "ordinary bin layout")
cases = cases + 1

files["/Applications/CMake.app/Contents/bin/cmake"] = true
assert(keys("/Applications")[1].value == "/Applications/CMake.app/Contents/bin", "macOS bundle layout")
cases = cases + 1

files["C:/Program Files/CMake/bin/cmake.exe"] = true
assert(keys("C:/Program Files/CMake")[1].value == "C:/Program Files/CMake/bin", "Windows bin layout")
cases = cases + 1

assert(keys("/unknown")[1].value == "/unknown/bin", "fallback when nothing exists")
cases = cases + 1

-- A binary detected directly in a PATH directory has that directory as its
-- root; EnvKeys must accept the root itself (version-fox/vfox-cmake#1 review).
files["/usr/local/bin/cmake"] = true
assert(keys("/usr/local/bin")[1].value == "/usr/local/bin", "binary at SDK root")
cases = cases + 1

print(("PASS %d env_keys checks"):format(cases))
