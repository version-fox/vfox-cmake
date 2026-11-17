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

local detect = require("detect_cmake")

--- Finds CMake installations vfox did not install, for
--- `vfox link --detect cmake`: system CMake, Homebrew, Scoop, Chocolatey,
--- an explicit CMAKE_HOME and everything already on PATH. Each entry names
--- the version the way `cmake --version` does, so `vfox link` treats it like
--- any other installable version.
--- @param ctx table Context information (reserved for future expansion)
--- @return table A list of { version, path, note } entries
function PLUGIN:Detect(ctx)
    return detect.find_all()
end
