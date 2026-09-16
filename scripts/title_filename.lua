-- ============================================================
--  title_filename.lua — 窗口标题自定义
-- ============================================================
--  功能：
--  根据 script-opts/title_filename.conf 中的 title_format 生成窗口标题，
--  默认显示完整文件名（含扩展名），避免有内嵌封面的音频
--  因 media-title 被元数据 title 覆盖而丢失扩展名。
--  支持按 UTF-8 字符数截断过长标题。
--  本脚本与 volume_fix.lua 完全独立，互不影响。
--  所有自定义都通过 title_filename.conf 完成，脚本本身无需修改。
-- ============================================================

local opt = require 'mp.options'
local opts = {
    -- 默认值，会被 script-opts/title_filename.conf 覆盖
    -- 支持 mpv 属性展开语法，例如 ${filename}、${media-title}
    title_format = "${filename}",

    -- 是否截断过长标题
    slice_longfilenames = false,
    -- 截断到多少个 UTF-8 字符（含省略号占位）
    slice_longfilenames_amount = 70,
}
opt.read_options(opts, "title_filename")

-- ============================================================
--  按 UTF-8 字符截断字符串
--  超过 max_chars 个字符时，截断并追加 "..."
-- ============================================================
local function utf8_truncate(s, max_chars)
    if not s or max_chars <= 0 then return s end
    local count = 0
    local result = {}
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > max_chars then
            return table.concat(result) .. "..."
        end
        result[#result + 1] = ch
    end
    return s
end

local function apply_title()
    if not opts.title_format or opts.title_format == "" then return end
    -- 延迟一点设置，确保 mpv 内部已更新过 title，避免被覆盖
    mp.add_timeout(0.05, function()
        local title = mp.command_native({"expand-text", opts.title_format})
        if not title or title == "" then return end
        if opts.slice_longfilenames then
            title = utf8_truncate(title, opts.slice_longfilenames_amount)
        end
        mp.set_property("title", title)
    end)
end

mp.register_event("file-loaded", apply_title)