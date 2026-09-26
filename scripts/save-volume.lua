-- ==============================================================================
-- save-volume.lua
-- 全局音量状态记忆：启动恢复、切集保持、关机自动存盘
-- ==============================================================================
local utils = require 'mp.utils'

-- 状态文件保存在 portable_config 根目录下
local state_file = mp.command_native({"expand-path", "~~/volume.state"})

-- 启动时自动恢复音量
local function load_volume()
    local f = io.open(state_file, "r")
    if f then
        local val = tonumber(f:read("*all"))
        f:close()
        if val and val >= 0 and val <= 100 then
            mp.set_property_number("volume", val)
        end
    end
end

-- 保存当前音量到状态文件
local function save_volume(vol)
    if not vol then
        vol = mp.get_property_number("volume")
    end
    if vol then
        local f = io.open(state_file, "w")
        if f then
            f:write(tostring(math.floor(vol + 0.5)))
            f:close()
        end
    end
end

-- 1. 启动立即加载
load_volume()

-- 2. 实时监听音量调节并持久化（防止异常闪退丢失状态）
mp.observe_property("volume", "number", function(_, vol)
    if vol then
        save_volume(vol)
    end
end)

-- 3. 正常退出播放器时确保刷新保存
mp.register_event("shutdown", function()
    save_volume()
end)