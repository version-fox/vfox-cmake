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
local version_order = require("version_order")

local cases = 0

local function newer(a, b)
    assert(version_order.newer(a, b), a .. " should be newer than " .. b)
    cases = cases + 1
end

local function not_newer(a, b)
    assert(not version_order.newer(a, b), a .. " should not be newer than " .. b)
    cases = cases + 1
end

newer("3.31.6", "3.28.1")
newer("4.0.0", "3.31.6")
newer("3.29", "3.28.9")
newer("3.28.1", "3.28")
not_newer("3.28.1", "3.28.1")
not_newer("3.27.9", "3.28.0")

-- A release is newer than each of its release candidates, and candidates
-- compare by number.
newer("4.5.0", "4.5.0-rc3")
newer("4.5.0", "4.5.0-rc1")
newer("4.5.0-rc3", "4.5.0-rc2")
newer("4.5.0-rc10", "4.5.0-rc9")
not_newer("4.5.0-rc3", "4.5.0")
not_newer("4.5.0-rc2", "4.5.0-rc3")
not_newer("4.5.0-rc3", "4.5.0-rc3")

-- A candidate is ordered by its numbers against releases of other versions.
newer("4.5.0-rc1", "4.4.5")
newer("4.5.1-rc1", "4.5.0")
not_newer("4.4.5", "4.5.0-rc1")

-- Any suffix sorts below the plain version, not only "rc".
newer("3.27.0", "3.27.0-msvc1")
not_newer("3.27.0-msvc1", "3.27.0")

-- Sorting puts the newest first. A candidate sits directly below its release,
-- and a candidate whose release is not in the list goes last.
local function check_order(input, expected)
    local entries = {}
    for i, version in ipairs(input) do
        entries[i] = { version = version }
    end
    local versions = {}
    for i, entry in ipairs(version_order.sort_newest_first(entries)) do
        versions[i] = entry.version
    end
    local got = table.concat(versions, " ")
    assert(got == expected, "sorting " .. table.concat(input, ", ") .. " gave " .. got .. ", want " .. expected)
    cases = cases + 1
end

check_order({ "4.5.0-rc1", "4.4.5", "4.5.0", "4.5.0-rc3", "4.5.0-rc2" }, "4.5.0 4.5.0-rc3 4.5.0-rc2 4.5.0-rc1 4.4.5")
check_order({ "4.6.0-rc1", "4.5.0", "4.5.0-rc1" }, "4.5.0 4.5.0-rc1 4.6.0-rc1")
check_order({ "4.6.0-rc1", "4.5.1-rc1", "4.5.0" }, "4.5.0 4.6.0-rc1 4.5.1-rc1")
check_order({ "4.6.0-rc1", "4.6.0-rc2" }, "4.6.0-rc2 4.6.0-rc1")
check_order({ "3.26.4", "3.27.0-msvc1", "3.28.1" }, "3.28.1 3.27.0-msvc1 3.26.4")

print(("PASS %d version order checks"):format(cases))
