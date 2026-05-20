local awful = require("awful")
local naughty = require("naughty")
local common = require("lib.common")

local ROFI_COMMAND = "~/.config/scripts/rofi-launch"
local LOCK_COMMAND = "~/.config/scripts/lock"
local SCREENSHOT_PATH = "~/.cache/com.pot-app.desktop/pot_screenshot_cut.png"
local POT_OCR_URL = "http://127.0.0.1:60828/ocr_translate?screenshot=false"

local M = {}

local truncate_message = common.truncate_message
local shell_quote = common.shell_quote

local function expand_home(path)
    return (path:gsub("^~", os.getenv("HOME") or "~"))
end

local function command_check(commands)
    local checks = {}
    for _, command in ipairs(commands) do
        checks[#checks + 1] = "command -v " .. shell_quote(command) .. " >/dev/null 2>&1"
    end
    return table.concat(checks, " && ")
end

local function executable_check(path)
    return "test -x " .. shell_quote(expand_home(path))
end

local function notify_action_failure(title, text)
    local preset = naughty.config
        and naughty.config.presets
        and (naughty.config.presets.warn or naughty.config.presets.warning)
        or nil

    naughty.notify({
        preset = preset,
        title = title,
        text = text,
    })
end

local function run_after_check(label, check_command, on_success, unavailable_message)
    awful.spawn.easy_async_with_shell(check_command, function(_, stderr, _, exit_code)
        if exit_code ~= 0 then
            notify_action_failure(label .. "不可用", unavailable_message or truncate_message(stderr) or "缺少运行所需命令。")
            return
        end

        on_success()
    end)
end

local function run_shell_after_check(label, check_command, shell_command, unavailable_message, report_failure)
    run_after_check(label, check_command, function()
        awful.spawn.easy_async_with_shell(shell_command, function(_, stderr, _, exit_code)
            if report_failure and exit_code ~= 0 then
                notify_action_failure(label .. "执行失败", truncate_message(stderr) or "命令返回非零状态。")
            end
        end)
    end, unavailable_message)
end

local function screenshot_ocr_command()
    local screenshot_path = expand_home(SCREENSHOT_PATH)
    local screenshot_dir = screenshot_path:match("^(.*)/[^/]+$") or (os.getenv("HOME") or ".")

    return "mkdir -p " .. shell_quote(screenshot_dir)
        .. " || exit 64; "
        .. "maim -s " .. shell_quote(screenshot_path)
        .. " || exit 0; "
        .. "curl --fail --silent --show-error " .. shell_quote(POT_OCR_URL) .. " >/dev/null"
end

function M.screenshot_ocr()
    run_shell_after_check(
        "截图 OCR",
        command_check({ "maim", "curl" }),
        screenshot_ocr_command(),
        "需要安装 maim 与 curl，并确认 Pot OCR 服务可用。",
        true
    )
end

function M.open_file_manager()
    run_after_check(
        "文件管理器",
        command_check({ "dolphin" }),
        function()
            awful.spawn("dolphin")
        end,
        "未找到 dolphin。"
    )
end

function M.launch_rofi()
    run_shell_after_check(
        "Rofi 启动器",
        executable_check(ROFI_COMMAND) .. " && " .. command_check({ "rofi" }),
        shell_quote(expand_home(ROFI_COMMAND)),
        "需要可执行的 ~/.config/scripts/rofi-launch 与 rofi。",
        false
    )
end

function M.lock()
    run_shell_after_check(
        "锁屏",
        executable_check(LOCK_COMMAND),
        shell_quote(expand_home(LOCK_COMMAND)),
        "需要可执行的 ~/.config/scripts/lock。",
        true
    )
end

M._private = {
    expand_home = expand_home,
    shell_quote = shell_quote,
    command_check = command_check,
    executable_check = executable_check,
    truncate_message = truncate_message,
    screenshot_ocr_command = screenshot_ocr_command,
}

return M
