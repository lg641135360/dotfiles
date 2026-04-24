local awful = require("awful")

local ROFI_COMMAND = "~/.config/scripts/rofi-launch"
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
