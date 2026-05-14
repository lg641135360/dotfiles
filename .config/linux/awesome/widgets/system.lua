-- System info widgets: CPU, MEM, NET, BAT
-- Returns a container with all system widgets and helper functions.

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local M = {}

local function read_file_line(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local content = file:read("*l")
    file:close()
    return content
end

local function read_file_all(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

local function parse_proc_stat_line(line)
    if not line or not line:match("^cpu%s+") then
        return nil
    end

    local values = {}
    for value in line:gmatch("%d+") do
        values[#values + 1] = tonumber(value) or 0
    end

    if #values < 4 then
        return nil
    end

    local total = 0
    for _, value in ipairs(values) do
        total = total + value
    end

    return {
        total = total,
        idle = (values[4] or 0) + (values[5] or 0),
    }
end

local function calculate_cpu_usage(previous, current)
    if not previous or not current then
        return nil
    end

    local total_delta = current.total - previous.total
    local idle_delta = current.idle - previous.idle

    if total_delta <= 0 or idle_delta < 0 then
        return nil
    end

    local busy_delta = math.max(total_delta - idle_delta, 0)
    return math.floor((busy_delta * 100 / total_delta) + 0.5)
end

local function parse_meminfo(content)
    if not content then
        return nil
    end

    local values = {}
    for key, value in content:gmatch("([%w_]+):%s+(%d+)") do
        values[key] = tonumber(value)
    end

    return values
end

local function calculate_mem_usage(values)
    if not values or not values.MemTotal or values.MemTotal <= 0 then
        return nil
    end

    local available = values.MemAvailable
    if not available then
        available = (values.MemFree or 0) + (values.Buffers or 0) + (values.Cached or 0)
    end

    if available < 0 then
        return nil
    end

    local used = math.max(values.MemTotal - available, 0)
    return math.floor((used * 100 / values.MemTotal) + 0.5)
end

local function usage_color(usage, warn_threshold, danger_threshold, ctpp)
    if not usage then
        return ctpp.overlay1
    elseif usage > danger_threshold then
        return ctpp.red
    elseif usage > warn_threshold then
        return ctpp.yellow
    end

    return ctpp.text
end

local function interface_matches(interface, patterns)
    for token in string.gmatch(patterns or "", "[^|]+") do
        if interface == token or interface:match("^" .. token) then
            return true
        end
    end

    return false
end

local function parse_default_route_interface(content, patterns)
    if not content then
        return nil
    end

    for line in content:gmatch("[^\r\n]+") do
        local interface, destination, _, flags = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
        if interface and destination == "00000000" then
            local flag_number = tonumber(flags, 16) or 0
            local route_is_up = (flag_number % 2) == 1
            if route_is_up and interface_matches(interface, patterns) then
                return interface
            end
        end
    end

    return nil
end

local function read_default_route_interface(patterns)
    return parse_default_route_interface(read_file_all("/proc/net/route"), patterns)
end

local function parse_network_totals(content, patterns)
    if not content then
        return {}
    end

    local entries = {}

    for line in content:gmatch("[^\r\n]+") do
        local interface, rest = line:match("^%s*([^:]+):%s*(.+)$")
        if interface and rest and interface_matches(interface, patterns) then
            local fields = {}
            for value in rest:gmatch("%S+") do
                fields[#fields + 1] = value
            end

            local recv = tonumber(fields[1])
            local sent = tonumber(fields[9])

            if recv and sent then
                entries[#entries + 1] = {
                    interface = interface,
                    recv = recv,
                    sent = sent,
                }
            end
        end
    end

    return entries
end

local function choose_network_totals(entries, preferred_interface)
    if preferred_interface then
        for _, entry in ipairs(entries or {}) do
            if entry.interface == preferred_interface then
                return entry
            end
        end
    end

    return entries and entries[1] or nil
end

local function read_network_totals(patterns)
    local content = read_file_all("/proc/net/dev")
    if not content then
        return nil
    end

    local entries = parse_network_totals(content, patterns)
    return choose_network_totals(entries, read_default_route_interface(patterns))
end

local function format_speed(bytes_per_sec)
    if bytes_per_sec < 1024 then
        return string.format("%.0fB", bytes_per_sec)
    elseif bytes_per_sec < 10 * 1024 then
        return string.format("%.1fK", bytes_per_sec / 1024)
    elseif bytes_per_sec < 1024 * 1024 then
        return string.format("%.0fK", bytes_per_sec / 1024)
    elseif bytes_per_sec < 10 * 1024 * 1024 then
        return string.format("%.1fM", bytes_per_sec / 1024 / 1024)
    elseif bytes_per_sec < 1024 * 1024 * 1024 then
        return string.format("%.0fM", bytes_per_sec / 1024 / 1024)
    end

    return string.format("%.1fG", bytes_per_sec / 1024 / 1024 / 1024)
end

local function find_battery_path()
    local handle = io.popen("for path in /sys/class/power_supply/*; do [ -d \"$path\" ] && printf '%s\\n' \"$path\"; done 2>/dev/null")
    if not handle then
        return nil
    end

    for path in handle:lines() do
        if read_file_line(path .. "/type") == "Battery" and read_file_line(path .. "/capacity") then
            handle:close()
            return path
        end
    end

    handle:close()
    return nil
end

local function render_metric_markup(label, label_color, value_text, value_color)
    return "<span foreground='" .. label_color .. "'>" .. label .. ":</span><span foreground='" .. value_color .. "'>" .. value_text .. "</span>"
end

local function read_load_average()
    local loadavg = read_file_line("/proc/loadavg")
    if not loadavg then
        return "N/A"
    end

    return loadavg:match("^(%S+%s+%S+%s+%S+)") or "N/A"
end

local function normalize_command_output(output, fallback)
    output = output or ""
    output = output:gsub("%s+$", "")

    if output == "" then
        return fallback
    end

    return output
end

local function system_details_command(section)
    if section == "cpu" then
        return "LC_ALL=C ps -eo pid,comm,%cpu --sort=-%cpu 2>/dev/null | head -n 5"
    end

    return "LC_ALL=C ps -eo pid,comm,%mem --sort=-%mem 2>/dev/null | head -n 5"
end

local function stop_timer(timer)
    if not timer then
        return
    end

    if timer.stop then
        timer:stop()
    elseif timer.started ~= nil then
        timer.started = false
    end
end

local function create_system_widgets(config, options)
    local compact = options and options.compact
    local ctpp = beautiful.ctpp
    local dpi = require("beautiful.xresources").apply_dpi
    local cpu_label = compact and "C" or "CPU"
    local mem_label = compact and "M" or "MEM"
    local battery_label = compact and "B" or "BAT"
    local system_state = {
        cpu_usage = "0%",
        mem_usage = "0%",
        load_average = "N/A",
        cpu_processes = "process list loading",
        mem_processes = "process list loading",
    }

    local function update_system_details_cache()
        system_state.load_average = read_load_average()

        awful.spawn.easy_async_with_shell(system_details_command("cpu"), function(stdout)
            system_state.cpu_processes = normalize_command_output(stdout, "process list unavailable")
        end)

        awful.spawn.easy_async_with_shell(system_details_command("mem"), function(stdout)
            system_state.mem_processes = normalize_command_output(stdout, "process list unavailable")
        end)
    end

    local function render_system_details_text(section)
        local is_cpu = section == "cpu"
        local title = is_cpu and "CPU" or "内存"
        local process_title = is_cpu and "Top CPU 进程" or "Top 内存进程"
        local process_output = is_cpu and system_state.cpu_processes or system_state.mem_processes
        local summary = is_cpu
            and ("使用率：" .. system_state.cpu_usage .. "\n负载：" .. system_state.load_average)
            or ("使用率：" .. system_state.mem_usage)

        return title
            .. "\n" .. summary
            .. "\n\n" .. process_title
            .. "\n" .. process_output
    end

    update_system_details_cache()
    local details_timer = gears.timer {
        timeout = 5,
        autostart = true,
        callback = update_system_details_cache,
    }

    -- CPU widget
    local cpu_widget = wibox.widget.textbox()
    cpu_widget:set_markup(render_metric_markup(cpu_label, ctpp.blue, "0%", ctpp.text))
    awful.tooltip {
        objects = { cpu_widget },
        timer_function = function()
            return render_system_details_text("cpu")
        end,
    }

    -- Memory widget
    local mem_widget = wibox.widget.textbox()
    mem_widget:set_markup(render_metric_markup(mem_label, ctpp.green, "0%", ctpp.text))
    awful.tooltip {
        objects = { mem_widget },
        timer_function = function()
            return render_system_details_text("mem")
        end,
    }

    local previous_cpu_totals = nil

    local function update_cpu()
        local current = parse_proc_stat_line(read_file_line("/proc/stat"))
        if not current then
            system_state.cpu_usage = "N/A"
            cpu_widget:set_markup(render_metric_markup(cpu_label, ctpp.blue, "N/A", ctpp.overlay1))
            return
        end

        local usage = calculate_cpu_usage(previous_cpu_totals, current)
        previous_cpu_totals = current

        if not usage then
            usage = 0
        end

        system_state.cpu_usage = usage .. "%"
        cpu_widget:set_markup(render_metric_markup(cpu_label, ctpp.blue, usage .. "%", usage_color(usage, 50, 80, ctpp)))
    end

    local function update_mem()
        local usage = calculate_mem_usage(parse_meminfo(read_file_all("/proc/meminfo")))
        if not usage then
            system_state.mem_usage = "N/A"
            mem_widget:set_markup(render_metric_markup(mem_label, ctpp.green, "N/A", ctpp.overlay1))
            return
        end

        system_state.mem_usage = usage .. "%"
        mem_widget:set_markup(render_metric_markup(mem_label, ctpp.green, usage .. "%", usage_color(usage, 60, 80, ctpp)))
    end

    update_cpu()
    update_mem()
    local metrics_timer = gears.timer {
        timeout = 2,
        autostart = true,
        callback = function()
            update_cpu()
            update_mem()
        end,
    }

    -- Network widget
    local net_widget = wibox.widget.textbox()
    local net_tooltip_text = "网络\n状态：离线\n接口：未匹配"

    local function render_net_markup(recv_speed, sent_speed)
        return "<span foreground='" .. ctpp.blue .. "'>↓" .. format_speed(recv_speed) .. "</span> <span foreground='" .. ctpp.peach .. "'>↑" .. format_speed(sent_speed) .. "</span>"
    end

    local function render_net_offline_markup()
        return "<span foreground='" .. ctpp.overlay0 .. "'>NET:N/A</span>"
    end

    local function update_net_tooltip(interface, recv_speed, sent_speed)
        net_tooltip_text = "网络"
            .. "\n接口：" .. interface
            .. "\n下载：" .. format_speed(recv_speed) .. "/s"
            .. "\n上传：" .. format_speed(sent_speed) .. "/s"
    end

    net_widget:set_markup(render_net_offline_markup())
    awful.tooltip {
        objects = { net_widget },
        timer_function = function()
            return net_tooltip_text
        end,
    }

    -- Battery widget (laptops only)
    local battery_widget = nil
    local battery_timer = nil
    local battery_path = find_battery_path()
    if battery_path then
        battery_widget = wibox.widget.textbox()
        battery_widget:set_markup(render_metric_markup(battery_label, ctpp.yellow, "0%", ctpp.text))
    end

    -- Network monitoring
    local net_prev = {}

    local function set_net_offline()
        net_prev.recv = nil
        net_prev.sent = nil
        net_widget:set_markup(render_net_offline_markup())
        net_tooltip_text = "网络\n状态：离线\n接口：未匹配"
    end

    local function update_net()
        local totals = read_network_totals(config.net_interfaces)
        if not totals then
            set_net_offline()
            return
        end

        if not net_prev.recv or not net_prev.sent then
            net_prev.recv = totals.recv
            net_prev.sent = totals.sent
            net_widget:set_markup(render_net_markup(0, 0))
            update_net_tooltip(totals.interface, 0, 0)
            return
        end

        local recv_speed = math.max(totals.recv - net_prev.recv, 0) / 2
        local sent_speed = math.max(totals.sent - net_prev.sent, 0) / 2

        net_widget:set_markup(render_net_markup(recv_speed, sent_speed))
        update_net_tooltip(totals.interface, recv_speed, sent_speed)
        net_prev.recv = totals.recv
        net_prev.sent = totals.sent
    end

    update_net()
    local net_timer = gears.timer {
        timeout = 2,
        autostart = true,
        callback = update_net,
    }

    if battery_widget then
        local battery_tooltip_text = battery_label .. "\n状态：读取中"

        local function translate_battery_status(status)
            local labels = {
                Charging = "充电中",
                Discharging = "放电中",
                Full = "已充满",
                ["Not charging"] = "未充电",
                Unknown = "未知",
            }

            return labels[status or ""] or (status and status ~= "" and status or "未知")
        end

        local function read_battery_number(path)
            local value = read_file_line(path)
            return value and tonumber(value) or nil
        end

        local function format_watts(microwatts)
            if not microwatts or microwatts <= 0 then
                return nil
            end

            return string.format("%.1fW", microwatts / 1000000)
        end

        local function format_duration(hours)
            if not hours or hours <= 0 or hours == math.huge then
                return nil
            end

            local total_minutes = math.floor(hours * 60 + 0.5)
            local h = math.floor(total_minutes / 60)
            local m = total_minutes % 60

            if h > 0 then
                return string.format("约%d小时%02d分", h, m)
            end

            return string.format("约%d分钟", m)
        end

        local function update_battery_tooltip(capacity, status)
            local energy_now = read_battery_number(battery_path .. "/energy_now")
            local energy_full = read_battery_number(battery_path .. "/energy_full")
            local charge_now = read_battery_number(battery_path .. "/charge_now")
            local charge_full = read_battery_number(battery_path .. "/charge_full")
            local current_now = read_battery_number(battery_path .. "/current_now")
            local voltage_now = read_battery_number(battery_path .. "/voltage_now")
            local power_now = read_battery_number(battery_path .. "/power_now")

            if not power_now and current_now and voltage_now then
                power_now = current_now * voltage_now / 1000000
            end

            local watts = format_watts(power_now)
            local duration_label = nil
            local duration_value = nil

            if power_now and power_now > 0 and energy_now then
                if status == "Discharging" and energy_now then
                    duration_label = "剩余"
                    duration_value = format_duration(energy_now / power_now)
                elseif status == "Charging" and energy_now and energy_full and energy_full > energy_now then
                    duration_label = "充满"
                    duration_value = format_duration((energy_full - energy_now) / power_now)
                end
            elseif current_now and current_now > 0 and charge_now then
                if status == "Discharging" then
                    duration_label = "剩余"
                    duration_value = format_duration(charge_now / current_now)
                elseif status == "Charging" and charge_full and charge_full > charge_now then
                    duration_label = "充满"
                    duration_value = format_duration((charge_full - charge_now) / current_now)
                end
            end

            battery_tooltip_text = battery_label
                .. "\n状态：" .. translate_battery_status(status)
                .. "\n电量：" .. (capacity and (capacity .. "%") or "N/A")

            if watts then
                battery_tooltip_text = battery_tooltip_text .. "\n功率：" .. watts
            end

            if duration_label and duration_value then
                battery_tooltip_text = battery_tooltip_text .. "\n" .. duration_label .. "：" .. duration_value
            end
        end

        awful.tooltip {
            objects = { battery_widget },
            timer_function = function()
                return battery_tooltip_text
            end,
        }

        local function update_battery()
            local capacity = tonumber(read_file_line(battery_path .. "/capacity"))
            if not capacity then
                return
            end

            local status = read_file_line(battery_path .. "/status")
            local color = ctpp.text
            if status == "Charging" then
                color = ctpp.green
            elseif capacity <= 15 then
                color = ctpp.red
            elseif capacity <= 35 then
                color = ctpp.yellow
            end

            battery_widget:set_markup(render_metric_markup(battery_label, ctpp.yellow, capacity .. "%", color))
            update_battery_tooltip(capacity, status)
        end

        update_battery()
        battery_timer = gears.timer {
            timeout = 30,
            autostart = true,
            callback = update_battery,
        }
    end

    -- Separator
    local function make_separator()
        return wibox.widget {
            markup = "<span foreground='" .. ctpp.surface1 .. "'>│</span>",
            widget = wibox.widget.textbox,
        }
    end

    local system_items = {
        net_widget,
        make_separator(),
        cpu_widget,
    }

    if not compact then
        table.insert(system_items, make_separator())
        table.insert(system_items, mem_widget)
    end

    if battery_widget then
        table.insert(system_items, make_separator())
        table.insert(system_items, battery_widget)
    end

    local system_row = wibox.layout.fixed.horizontal()
    system_row.spacing = 2
    for _, item in ipairs(system_items) do
        system_row:add(item)
    end

    -- System info container
    local sysinfo_widget = wibox.widget {
        system_row,
        bg = ctpp.surface0,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        left = 4,
        right = 4,
        top = 4,
        bottom = 4,
        widget = wibox.container.margin,
    }

    local function dispose()
        stop_timer(details_timer)
        stop_timer(metrics_timer)
        stop_timer(net_timer)
        if battery_timer then
            stop_timer(battery_timer)
        end
    end

    return {
        sysinfo_widget = sysinfo_widget,
        system_row = system_row,
        cpu_widget = cpu_widget,
        mem_widget = mem_widget,
        net_widget = net_widget,
        battery_widget = battery_widget,
        make_separator = make_separator,
        dispose = dispose,
    }
end

M.create = create_system_widgets

M._private = {
    parse_proc_stat_line = parse_proc_stat_line,
    calculate_cpu_usage = calculate_cpu_usage,
    parse_meminfo = parse_meminfo,
    calculate_mem_usage = calculate_mem_usage,
    interface_matches = interface_matches,
    parse_default_route_interface = parse_default_route_interface,
    parse_network_totals = parse_network_totals,
    choose_network_totals = choose_network_totals,
    format_speed = format_speed,
    stop_timer = stop_timer,
}

return M
