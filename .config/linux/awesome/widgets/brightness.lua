-- Brightness widget using native backlight sysfs
-- Shows only when a backlight device is available; scroll control is optional via brightnessctl

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local wibox = require("wibox")
local beautiful = require("beautiful")
local common = require("lib.common")

local read_command_output = common.read_command_output
local command_exists = common.command_exists
local stop_timer = common.stop_timer
local truncate_message = common.truncate_message
local shell_quote = common.shell_quote

local function read_file_line(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local content = file:read("*l")
    file:close()
    return content
end

local function find_backlight_path()
    local handle = io.popen("for path in /sys/class/backlight/*; do [ -d \"$path\" ] && printf '%s\\n' \"$path\"; done 2>/dev/null")
    if not handle then
        return nil
    end

    for path in handle:lines() do
        if read_file_line(path .. "/brightness") and read_file_line(path .. "/max_brightness") then
            handle:close()
            return path
        end
    end

    handle:close()
    return nil
end

local function read_brightness_number(path)
    local value = read_file_line(path)
    return value and tonumber(value) or nil
end

local function calculate_brightness_percent(current, maximum)
    if current == nil or maximum == nil or maximum <= 0 or current < 0 then
        return nil
    end

    return math.floor((current * 100 / maximum) + 0.5)
end

local function notify_brightness_failure(title, text)
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

local function file_writable(path)
    return read_command_output("[ -w " .. shell_quote(path) .. " ] && printf yes || printf no") == "yes"
end

local function file_group_name(path)
    return read_command_output("stat -c %G " .. shell_quote(path))
end

local function user_in_group(group_name)
    if not group_name or group_name == "" then
        return false
    end

    local groups = read_command_output("id -nG")
    if not groups then
        return false
    end

    for token in groups:gmatch("%S+") do
        if token == group_name then
            return true
        end
    end

    return false
end

local function brightnessctl_install_hint()
    if command_exists("apt") then
        return "sudo apt install brightnessctl"
    end

    if command_exists("pacman") then
        return "sudo pacman -S brightnessctl"
    end

    if command_exists("dnf") then
        return "sudo dnf install brightnessctl"
    end

    return "请用系统包管理器安装 brightnessctl"
end

local function brightness_permission_hint(brightness_file)
    local group_name = file_group_name(brightness_file)
    if group_name and group_name ~= "" and group_name ~= "root" and not user_in_group(group_name) then
        return "当前用户没有写入背光设备的权限。\n可执行：sudo usermod -aG " .. group_name .. " $USER\n然后重新登录。"
    end

    return "当前用户没有写入背光设备的权限。\n可尝试：sudo usermod -aG video $USER\n然后重新登录；或调整背光设备权限。"
end

local function create_brightness_widget(options)
    local brightness_path = (options and options.path) or find_backlight_path()
    if not brightness_path then
        return nil
    end

    local ctpp = beautiful.ctpp
    local compact = options and options.compact
    local has_brightnessctl = options and options.can_adjust
    local device_name = brightness_path:match("([^/]+)$") or "backlight"
    local brightness_label = compact and "L" or "BRI"
    local brightness_file = brightness_path .. "/brightness"

    if has_brightnessctl == nil then
        has_brightnessctl = command_exists("brightnessctl")
    end

    local can_write_brightness = file_writable(brightness_file)

    local function render_unavailable_markup()
        return "<span foreground='" .. ctpp.sky .. "'>" .. brightness_label .. ":</span><span foreground='" .. ctpp.overlay1 .. "'>N/A</span>"
    end

    local function render_brightness_markup(percent)
        if percent == nil then
            return render_unavailable_markup()
        end

        local value_color = ctpp.text
        if percent <= 15 then
            value_color = ctpp.red
        elseif percent <= 35 then
            value_color = ctpp.yellow
        end

        return "<span foreground='" .. ctpp.sky .. "'>" .. brightness_label .. ":</span><span foreground='" .. value_color .. "'>" .. percent .. "%</span>"
    end

    local brightness_widget = wibox.widget.textbox()
    local brightness_tooltip_status = brightness_label .. ": N/A"
    local last_percent = nil
    local last_current = nil
    local last_maximum = nil
    brightness_widget:set_markup(render_unavailable_markup())

    local function set_brightness_tooltip_status(percent)
        if percent == nil then
            brightness_tooltip_status = brightness_label .. ": N/A"
            return
        end

        brightness_tooltip_status = brightness_label .. ": " .. percent .. "%"
    end

    local function render_brightness_tooltip()
        local lines = {
            "亮度",
            "状态：" .. brightness_tooltip_status,
            "设备：" .. device_name,
        }

        if last_current ~= nil and last_maximum ~= nil then
            lines[#lines + 1] = "原始：" .. last_current .. " / " .. last_maximum
        end

        if has_brightnessctl and can_write_brightness then
            lines[#lines + 1] = "滚轮：调整亮度"
        elseif not has_brightnessctl then
            lines[#lines + 1] = "滚轮：未启用（缺少 brightnessctl）"
        else
            lines[#lines + 1] = "滚轮：未启用（权限不足）"
        end

        return table.concat(lines, "\n")
    end

    awful.tooltip {
        objects = { brightness_widget },
        timer_function = function()
            return render_brightness_tooltip()
        end,
    }

    local function update_brightness()
        local current = read_brightness_number(brightness_path .. "/actual_brightness")
            or read_brightness_number(brightness_path .. "/brightness")
        local maximum = read_brightness_number(brightness_path .. "/max_brightness")
        local percent = calculate_brightness_percent(current, maximum)

        last_current = current
        last_maximum = maximum
        last_percent = percent

        brightness_widget:set_markup(render_brightness_markup(percent))
        set_brightness_tooltip_status(percent)
    end

    local function refresh_after_input_change()
        local refresh_delays = { 0.15, 0.5, 1.2 }

        for _, delay in ipairs(refresh_delays) do
            gears.timer.start_new(delay, function()
                update_brightness()
                return false
            end)
        end
    end

    local function notify_missing_brightnessctl()
        notify_brightness_failure("亮度调节不可用", "未找到 brightnessctl。\n安装：" .. brightnessctl_install_hint())
    end

    local function notify_brightness_permission_denied()
        notify_brightness_failure("亮度调节权限不足", brightness_permission_hint(brightness_file))
    end

    local function adjust_brightness(step)
        if not has_brightnessctl then
            notify_missing_brightnessctl()
            return
        end

        if not can_write_brightness then
            notify_brightness_permission_denied()
            return
        end

        awful.spawn.easy_async_with_shell(
            "brightnessctl -q -d " .. shell_quote(device_name) .. " set " .. step,
            function(stdout, stderr, _, exit_code)
                if exit_code ~= 0 then
                    local error_text = truncate_message(stderr) or truncate_message(stdout)
                    if error_text and error_text:lower():match("permission denied") then
                        notify_brightness_permission_denied()
                    else
                        notify_brightness_failure("亮度调节执行失败", error_text or "brightnessctl 执行失败。")
                    end
                    refresh_after_input_change()
                    return
                end

                refresh_after_input_change()
            end
        )
    end

    update_brightness()
    local refresh_timer = gears.timer {
        timeout = 10,
        autostart = true,
        callback = update_brightness,
    }

    brightness_widget:buttons(gears.table.join(
        awful.button({ }, 4, function()
            adjust_brightness("5%+")
        end),
        awful.button({ }, 5, function()
            adjust_brightness("5%-")
        end)
    ))

    local function dispose()
        stop_timer(refresh_timer)
    end

    return {
        widget = brightness_widget,
        update = update_brightness,
        dispose = dispose,
    }
end

return {
    create = create_brightness_widget,
    _private = {
        find_backlight_path = find_backlight_path,
        read_brightness_number = read_brightness_number,
        calculate_brightness_percent = calculate_brightness_percent,
        command_exists = command_exists,
        stop_timer = stop_timer,
        brightnessctl_install_hint = brightnessctl_install_hint,
        brightness_permission_hint = brightness_permission_hint,
        shell_quote = shell_quote,
    },
}
