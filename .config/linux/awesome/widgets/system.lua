-- System info widgets: CPU, MEM, NET
-- Returns a container with all system widgets and helper functions

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

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

    local function read_file(path)
        local file = io.open(path, "r")
        if not file then
            return nil
        end

        local content = file:read("*l")
        file:close()
        return content
    end

    local function find_battery_path()
        local handle = io.popen("for path in /sys/class/power_supply/*; do [ -d \"$path\" ] && printf '%s\\n' \"$path\"; done 2>/dev/null")
        if not handle then
            return nil
        end

        for path in handle:lines() do
            if read_file(path .. "/type") == "Battery" and read_file(path .. "/capacity") then
                handle:close()
                return path
            end
        end

        handle:close()
        return nil
    end

    local function interface_matches(interface)
        for token in string.gmatch(config.net_interfaces or "", "[^|]+") do
            if interface == token or interface:match("^" .. token) then
                return true
            end
        end

        return false
    end

    local function read_network_totals()
        local dev_file = io.open("/proc/net/dev", "r")
        if not dev_file then
            return nil
        end

        for line in dev_file:lines() do
            local interface, rest = line:match("^%s*([^:]+):%s*(.+)$")
            if interface and rest and interface_matches(interface) then
                local fields = {}
                for value in rest:gmatch("%S+") do
                    fields[#fields + 1] = value
                end

                local recv = tonumber(fields[1])
                local sent = tonumber(fields[9])

                if recv and sent then
                    dev_file:close()
                    return {
                        interface = interface,
                        recv = recv,
                        sent = sent,
                    }
                end
            end
        end

        dev_file:close()
        return nil
    end

    local function render_metric_markup(label, label_color, value_text, value_color)
        return "<span foreground='" .. label_color .. "'>" .. label .. ":</span><span foreground='" .. value_color .. "'>" .. value_text .. "</span>"
    end

    local function read_load_average()
        local loadavg = read_file("/proc/loadavg")
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
    gears.timer {
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
        else
            return string.format("%.1fG", bytes_per_sec / 1024 / 1024 / 1024)
        end
    end

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
    local battery_path = find_battery_path()
    if battery_path then
        battery_widget = wibox.widget.textbox()
        battery_widget:set_markup(render_metric_markup(battery_label, ctpp.yellow, "0%", ctpp.text))
    end

    -- Load lain for CPU and MEM
    local lain = require("lain")

    lain.widget.cpu {
        timeout = 2,
        settings = function()
            local color = ctpp.text
            if tonumber(cpu_now.usage) > 80 then
                color = ctpp.red
            elseif tonumber(cpu_now.usage) > 50 then
                color = ctpp.yellow
            end
            system_state.cpu_usage = cpu_now.usage .. "%"
            cpu_widget:set_markup(render_metric_markup(cpu_label, ctpp.blue, cpu_now.usage .. "%", color))
        end,
    }

    lain.widget.mem {
        timeout = 2,
        settings = function()
            local color = ctpp.text
            if tonumber(mem_now.perc) > 80 then
                color = ctpp.red
            elseif tonumber(mem_now.perc) > 60 then
                color = ctpp.yellow
            end
            system_state.mem_usage = mem_now.perc .. "%"
            mem_widget:set_markup(render_metric_markup(mem_label, ctpp.green, mem_now.perc .. "%", color))
        end,
    }

    -- Network monitoring
    local net_prev = {}

    local function set_net_offline()
        net_prev.recv = nil
        net_prev.sent = nil
        net_widget:set_markup(render_net_offline_markup())
        net_tooltip_text = "网络\n状态：离线\n接口：未匹配"
    end

    local function update_net()
        local totals = read_network_totals()
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
    gears.timer {
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
            local value = read_file(path)
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
            local capacity = tonumber(read_file(battery_path .. "/capacity"))
            if not capacity then
                return
            end

            local status = read_file(battery_path .. "/status")
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
        gears.timer {
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

    return {
        sysinfo_widget = sysinfo_widget,
        system_row = system_row,
        cpu_widget = cpu_widget,
        mem_widget = mem_widget,
        net_widget = net_widget,
        battery_widget = battery_widget,
        make_separator = make_separator,
    }
end

return {
    create = create_system_widgets,
}
