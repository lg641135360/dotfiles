local awful = require("awful")

local ROFI_COMMAND = "LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx rofi -show drun"
local SCREENSHOT_OCR_COMMAND = "maim -s ~/.cache/com.pot-app.desktop/pot_screenshot_cut.png && curl '127.0.0.1:60828/ocr_translate?screenshot=false'"
local LOCK_COMMAND = "~/.config/scripts/lock"

local M = {}

function M.screenshot_ocr()
    awful.spawn.with_shell(SCREENSHOT_OCR_COMMAND)
end

function M.open_file_manager()
    awful.spawn("dolphin")
end

function M.launch_rofi()
    awful.spawn.with_shell(ROFI_COMMAND)
end

function M.lock()
    awful.spawn.with_shell(LOCK_COMMAND)
end

return M
