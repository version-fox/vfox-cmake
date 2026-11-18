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

--- Orders CMake version strings such as "4.5.0" and "4.5.0-rc3". The release
--- list (lib/util.lua) and the Detect hook (lib/detect_cmake.lua) both use it,
--- so they agree on which version is the newest.
local version_order = {}

--- Splits a version into its numeric text, its numeric parts and its suffix.
--- "4.5.0-rc3" gives "4.5.0", {4, 5, 0} and "rc3"; "4.5.0" gives nil as suffix.
local function parse(version)
    local core, suffix = string.match(version, "^([^-]*)%-(.*)$")
    if core == nil then
        core = version
    end
    local numbers = {}
    for part in string.gmatch(core, "[^.]+") do
        table.insert(numbers, tonumber(part) or 0)
    end
    return core, numbers, suffix
end

--- Splits a suffix into its label and number: "rc3" gives "rc" and 3.
local function parse_suffix(suffix)
    local label, number = string.match(suffix, "^(%D*)(%d*)$")
    if label == nil then
        return suffix, 0
    end
    return label, tonumber(number) or 0
end

--- Returns true when version a sorts after version b. Numeric parts compare
--- first. Then a version without a suffix is newer than the same version with
--- one, so 4.5.0 is newer than 4.5.0-rc3. Suffixes compare by label, then by
--- number, so 4.5.0-rc10 is newer than 4.5.0-rc9.
--- @param a string
--- @param b string
--- @return boolean
function version_order.newer(a, b)
    local _, a_numbers, a_suffix = parse(a)
    local _, b_numbers, b_suffix = parse(b)
    for i = 1, math.max(#a_numbers, #b_numbers) do
        local a_part, b_part = a_numbers[i] or 0, b_numbers[i] or 0
        if a_part ~= b_part then
            return a_part > b_part
        end
    end

    if a_suffix == b_suffix then
        return false
    elseif a_suffix == nil then
        return true
    elseif b_suffix == nil then
        return false
    end

    local a_label, a_number = parse_suffix(a_suffix)
    local b_label, b_number = parse_suffix(b_suffix)
    if a_label ~= b_label then
        return a_label > b_label
    end
    return a_number > b_number
end

--- Sorts entries in place, newest first. Each entry is a table with a version
--- field, such as { version = "4.5.0" }.
---
--- A release candidate ("rc" suffix) sits directly below its release. A
--- candidate whose release is not in the list goes after every other entry.
--- vfox installs the first entry for `latest`, so that entry is a release
--- whenever the list has one. Other suffixes are ordered by version alone.
--- @param entries table
--- @return table The same table, sorted
function version_order.sort_newest_first(entries)
    local released = {}
    for _, entry in ipairs(entries) do
        local core, _, suffix = parse(entry.version)
        if suffix == nil then
            released[core] = true
        end
    end

    local function unreleased(entry)
        local core, _, suffix = parse(entry.version)
        if suffix == nil then
            return false
        end
        local label = parse_suffix(suffix)
        return label == "rc" and not released[core]
    end

    table.sort(entries, function(a, b)
        local a_unreleased, b_unreleased = unreleased(a), unreleased(b)
        if a_unreleased ~= b_unreleased then
            return b_unreleased
        end
        return version_order.newer(a.version, b.version)
    end)
    return entries
end

return version_order
