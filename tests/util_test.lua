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
local util = require("util")

local cases = 0

local function newer(a, b)
    assert(util:compare_versions({ version = a }, { version = b }), a .. " should be newer than " .. b)
    cases = cases + 1
end

local function not_newer(a, b)
    assert(not util:compare_versions({ version = a }, { version = b }), a .. " should not be newer than " .. b)
    cases = cases + 1
end

newer("3.31.6", "3.28.1")
newer("4.0.0", "3.31.6")
newer("3.29", "3.28.9")
newer("3.28.1", "3.28")
not_newer("3.28.1", "3.28.1")
not_newer("3.27.9", "3.28.0")

print(("PASS %d util checks"):format(cases))
