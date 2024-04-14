local http = require("http")
local json = require("json")

local util = {}

util.__index = util
local utilSingleton = setmetatable({}, util)

utilSingleton.BASE_URL = "https://cmake.org/files/"
utilSingleton.RELEASES ={}

function util:compare_versions(v1o, v2o)
    local v1 = v1o.version
    local v2 = v2o.version
    local v1_parts = {}
    for part in string.gmatch(v1, "[^.]+") do
        table.insert(v1_parts, tonumber(part))
    end

    local v2_parts = {}
    for part in string.gmatch(v2, "[^.]+") do
        table.insert(v2_parts, tonumber(part))
    end

    for i = 1, math.max(#v1_parts, #v2_parts) do
        local v1_part = v1_parts[i] or 0
        local v2_part = v2_parts[i] or 0
        if v1_part > v2_part then
            return true
        elseif v1_part < v2_part then
            return false
        end
    end

    return false
end

function util:getInfo()
    local result = {}
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/ahai-code/vfox-cmake@main/assets/version.json"
    })

    if err ~= nil then
        error("Failed to get information: " .. err)
    end
    if resp.status_code ~= 200 then
        error("Failed to get information: status_code =>" .. resp.status_code)
    end

    local respInfo = json.decode(resp.body)[RUNTIME.osType]

    for _, info in pairs(respInfo) do
        for _, obj in ipairs(info) do
            if obj.arch=="" then
                table.insert(result, {version = obj.version,note=""})
                table.insert(utilSingleton.RELEASES,{version = obj.version,url=obj.download_url,sha256=obj.sha256})
            elseif obj.arch == RUNTIME.archType then
                table.insert(result, {version = obj.version,note=""})
                table.insert(utilSingleton.RELEASES,{version = obj.version,url=obj.download_url,sha256=obj.sha256})
            end
        end
    end
    table.sort(result, function(a, b)
        return util:compare_versions(a,b)
    end)
    return result
end

return utilSingleton