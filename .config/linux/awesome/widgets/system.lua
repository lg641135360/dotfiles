-- System info widgets: CPU, MEM, NET, BAT
-- Returns a container with all system widgets and helper functions.

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local common = require("lib.common")

local M = {}

local stop_timer = common.stop_timer

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

    return ctpp.subtext0
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

local function find_battery_paths()
    local handle = io.popen("for path in /sys/class/power_supply/*; do [ -d \"$path\" ] && printf '%s\\n' \"$path\"; done 2>/dev/null")
    if not handle then
        return {}
    end

    local battery_paths = {}

    for path in handle:lines() do
        if read_file_line(path .. "/type") == "Battery" and read_file_line(path .. "/capacity") then
            battery_paths[#battery_paths + 1] = path
        end
    end

    handle:close()
    return battery_paths
end

local function sum_snapshot_field(snapshots, key)
    local total = 0
    local found = false

    for _, snapshot in ipairs(snapshots or {}) do
        if snapshot[key] ~= nil then
            total = total + snapshot[key]
            found = true
        end
    end

    return found and total or nil
end

local function weighted_capacity(now_value, full_value)
    if now_value == nil or full_value == nil or full_value <= 0 then
        return nil
    end

    return math.floor((now_value * 100 / full_value) + 0.5)
end

local function average_capacity(snapshots)
    local total = 0
    local count = 0

    for _, snapshot in ipairs(snapshots or {}) do
        if snapshot.capacity ~= nil then
            total = total + snapshot.capacity
            count = count + 1
        end
    end

    if count == 0 then
        return nil
    end

    return math.floor((total / count) + 0.5)
end

local function aggregate_battery_status(snapshots)
    if not snapshots or #snapshots == 0 then
        return nil
    end

    local has_charging = false
    local has_discharging = false
    local has_full = false
    local has_not_charging = false

    for _, snapshot in ipairs(snapshots) do
        if snapshot.status == "Charging" then
            has_charging = true
        elseif snapshot.status == "Discharging" then
            has_discharging = true
        elseif snapshot.status == "Full" then
            has_full = true
        elseif snapshot.status == "Not charging" then
            has_not_charging = true
        end
    end

    if has_charging then
        return "Charging"
    end

    if has_discharging then
        return "Discharging"
    end

    if has_not_charging then
        return "Not charging"
    end

    if has_full then
        return "Full"
    end

    return "Unknown"
end

local function aggregate_battery_readings(snapshots)
    if not snapshots or #snapshots == 0 then
        return nil
    end

    local summary = {
        count = #snapshots,
        status = aggregate_battery_status(snapshots),
    }

    summary.energy_now = sum_snapshot_field(snapshots, "energy_now")
    summary.energy_full = sum_snapshot_field(snapshots, "energy_full")
    summary.charge_now = sum_snapshot_field(snapshots, "charge_now")
    summary.charge_full = sum_snapshot_field(snapshots, "charge_full")
    summary.current_now = sum_snapshot_field(snapshots, "current_now")
    summary.power_now = sum_snapshot_field(snapshots, "power_now")
    summary.capacity = weighted_capacity(summary.energy_now, summary.energy_full)
        or weighted_capacity(summary.charge_now, summary.charge_full)
        or average_capacity(snapshots)

    return summary
end

local function render_metric_markup(label, value_text, color)
    return "<span foreground='" .. color .. "'>" .. label .. "\u{2009}" .. value_text .. "</span>"
end

local function read_load_average()
    local loadavg = read_file_line("/proc/loadavg")
    if not loadavg then
        return "N/A"
    end

    return loadavg:match("^(%S+%s+%S+%s+%S+)") or "N/A"
end

-- Parse top CPU/MEM processes natively in Lua (no ps subprocess).
-- A single /proc walk feeds both lists; refresh only happens on hover.
local CLK_TCK = 100

local function read_proc_uptime()
    local line = read_file_line("/proc/uptime")
    if not line then
        return 0
    end

    return tonumber(line:match("^([%d%.]+)")) or 0
end

local function list_proc_pids()
    local handle = io.popen("ls /proc 2>/dev/null")
    if not handle then
        return {}
    end

    local pids = {}
    for line in handle:lines() do
        local pid = line:match("^(%d+)$")
        if pid then
            pids[#pids + 1] = pid
        end
    end
    handle:close()
    return pids
end

-- /proc/<pid>/stat: pid (comm) state ppid ...; fields after ")" start at index 3
local function parse_proc_stat_fields(content)
    if not content then
        return nil
    end

    local close = content:find("%)")
    if not close then
        return nil
    end

    local fields = {}
    for value in content:sub(close + 2):gmatch("%S+") do
        fields[#fields + 1] = value
    end

    -- field 14 utime, 15 stime, 22 starttime (rest index = field - 2)
    local utime = tonumber(fields[12])
    local stime = tonumber(fields[13])
    local starttime = tonumber(fields[20])

    if not utime or not stime or not starttime then
        return nil
    end

    return utime, stime, starttime
end

local function compute_process_cpu(utime, stime, starttime, uptime)
    if not utime or not stime or not starttime then
        return nil
    end

    -- btime cancels out: process elapsed = uptime - starttime/CLK_TCK
    local elapsed = uptime - (starttime / CLK_TCK)
    if elapsed <= 0 then
        return nil
    end

    return (utime + stime) / CLK_TCK / elapsed * 100
end

local function read_process_comm(pid)
    return read_file_line("/proc/" .. pid .. "/comm") or pid
end

local function read_process_rss(pid)
    local status = read_file_all("/proc/" .. pid .. "/status")
    if not status then
        return nil
    end

    local rss = status:match("VmRSS:%s+(%d+)")
    return rss and tonumber(rss) or nil
end

local function collect_process_details()
    local uptime = read_proc_uptime()
    local cpu_entries = {}
    local mem_entries = {}

    for _, pid in ipairs(list_proc_pids()) do
        local utime, stime, starttime = parse_proc_stat_fields(read_file_all("/proc/" .. pid .. "/stat"))
        local cpu = compute_process_cpu(utime, stime, starttime, uptime)
        local rss = cpu and read_process_rss(pid)

        if cpu or rss then
            local comm = read_process_comm(pid)
            if cpu then
                cpu_entries[#cpu_entries + 1] = { pid = pid, comm = comm, value = cpu }
            end
            if rss then
                mem_entries[#mem_entries + 1] = { pid = pid, comm = comm, value = rss }
            end
        end
    end

    table.sort(cpu_entries, function(a, b) return a.value > b.value end)
    table.sort(mem_entries, function(a, b) return a.value > b.value end)
    return cpu_entries, mem_entries
end

local function format_memory_kb(kb)
    if kb >= 1024 * 1024 then
        return string.format("%.1fG", kb / 1024 / 1024)
    elseif kb >= 1024 then
        return string.format("%.0fM", kb / 1024)
    end

    return kb .. "K"
end

local function format_process_list(entries, is_cpu)
    local lines = {}
    local count = 0

    for _, entry in ipairs(entries) do
        if count >= 5 then
            break
        end

        local value = is_cpu
            and string.format("%.0f%%", entry.value)
            or format_memory_kb(entry.value)

        lines[#lines + 1] = entry.pid .. "  " .. entry.comm .. "  " .. value
        count = count + 1
    end

    if #lines == 0 then
        return "process list unavailable"
    end

    return table.concat(lines, "\n")
end

local function create_system_widgets(config, options)
    local compact = options and options.compact
    local ctpp = beautiful.ctpp
    local dpi = require("beautiful.xresources").apply_dpi
    local cpu_label = "󰻠"
    local mem_label = "󰍛"
    local battery_label = "󰁹"
    local system_state = {
        cpu_usage = "0%",
        mem_usage = "0%",
        load_average = "N/A",
        cpu_processes = "process list loading",
        mem_processes = "process list loading",
    }

    local function update_system_details_cache()
        system_state.load_average = read_load_average()
        local cpu_entries, mem_entries = collect_process_details()
        system_state.cpu_processes = format_process_list(cpu_entries, true)
        system_state.mem_processes = format_process_list(mem_entries, false)
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

    -- Lazy-load top process details on hover instead of polling every 5s.
    -- `mouse::enter` is emitted by the widget (not the tooltip object), so mark
    -- the cache dirty there; the tooltip's timer_function then refreshes once on
    -- the first render, so the tooltip shows real data instead of "loading".
    local details_dirty = true
    local function refresh_details_on_hover()
        details_dirty = true
    end

    -- CPU widget
    local cpu_widget = wibox.widget.textbox()
    cpu_widget:set_markup(render_metric_markup(cpu_label, "0", ctpp.subtext0))
    cpu_widget:connect_signal("mouse::enter", refresh_details_on_hover)

    -- Memory widget
    local mem_widget = wibox.widget.textbox()
    mem_widget:set_markup(render_metric_markup(mem_label, "0", ctpp.subtext0))
    mem_widget:connect_signal("mouse::enter", refresh_details_on_hover)

    local function render_cpu_tooltip()
        if details_dirty then
            update_system_details_cache()
            details_dirty = false
        end
        return render_system_details_text("cpu")
    end

    local function render_mem_tooltip()
        if details_dirty then
            update_system_details_cache()
            details_dirty = false
        end
        return render_system_details_text("mem")
    end

    local cpu_tooltip = awful.tooltip {
        objects = { cpu_widget },
        timer_function = render_cpu_tooltip,
    }
    local mem_tooltip = awful.tooltip {
        objects = { mem_widget },
        timer_function = render_mem_tooltip,
    }

    local previous_cpu_totals = nil

    local function update_cpu()
        local current = parse_proc_stat_line(read_file_line("/proc/stat"))
        if not current then
            system_state.cpu_usage = "N/A"
            cpu_widget:set_markup(render_metric_markup(cpu_label, "N/A", ctpp.overlay1))
            return
        end

        local usage = calculate_cpu_usage(previous_cpu_totals, current)
        previous_cpu_totals = current

        if not usage then
            usage = 0
        end

        system_state.cpu_usage = usage .. "%"
        cpu_widget:set_markup(render_metric_markup(cpu_label, tostring(usage), usage_color(usage, 50, 80, ctpp)))
    end

    local function update_mem()
        local usage = calculate_mem_usage(parse_meminfo(read_file_all("/proc/meminfo")))
        if not usage then
            system_state.mem_usage = "N/A"
            mem_widget:set_markup(render_metric_markup(mem_label, "N/A", ctpp.overlay1))
            return
        end

        system_state.mem_usage = usage .. "%"
        mem_widget:set_markup(render_metric_markup(mem_label, tostring(usage), usage_color(usage, 60, 80, ctpp)))
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
    local net_tooltip_text = "网络\n接口：未匹配"

    local function render_net_markup(recv_speed, sent_speed)
        local active = (recv_speed + sent_speed) > 0
        local down_color = active and ctpp.blue or ctpp.overlay1
        local up_color = active and ctpp.peach or ctpp.overlay1
        return "<span foreground='" .. down_color .. "'>↓" .. format_speed(recv_speed) .. "</span> <span foreground='" .. up_color .. "'>↑" .. format_speed(sent_speed) .. "</span>"
    end

    local function render_net_offline_markup()
        return "<span foreground='" .. ctpp.overlay0 .. "'>N/A</span>"
    end

    local function update_net_tooltip(interface, recv_speed, sent_speed)
        net_tooltip_text = "网络"
            .. "\n接口：" .. interface
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
    local battery_paths = find_battery_paths()
    if #battery_paths > 0 then
        battery_widget = wibox.widget.textbox()
        battery_widget:set_markup(render_metric_markup(battery_label, "0", ctpp.subtext0))
    end

    -- Network monitoring
    local net_prev = {}

    local function set_net_offline()
        net_prev.recv = nil
        net_prev.sent = nil
        net_widget:set_markup(render_net_offline_markup())
        net_tooltip_text = "网络\n接口：未匹配"
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

        local function read_battery_number(path)
            local value = read_file_line(path)
            return value and tonumber(value) or nil
        end

        local function collect_battery_snapshot(battery_path)
            local current_now = read_battery_number(battery_path .. "/current_now")
            local voltage_now = read_battery_number(battery_path .. "/voltage_now")
            local power_now = read_battery_number(battery_path .. "/power_now")

            if not power_now and current_now and voltage_now then
                power_now = current_now * voltage_now / 1000000
            end

            return {
                capacity = read_battery_number(battery_path .. "/capacity"),
                status = read_file_line(battery_path .. "/status"),
                energy_now = read_battery_number(battery_path .. "/energy_now"),
                energy_full = read_battery_number(battery_path .. "/energy_full"),
                charge_now = read_battery_number(battery_path .. "/charge_now"),
                charge_full = read_battery_number(battery_path .. "/charge_full"),
                current_now = current_now,
                power_now = power_now,
            }
        end

        local function update_battery_tooltip(summary)
            local watts = format_watts(summary.power_now)
            local duration_label = nil
            local duration_value = nil

            if summary.power_now and summary.power_now > 0 and summary.energy_now then
                if summary.status == "Discharging" and summary.energy_now then
                    duration_label = "剩余"
                    duration_value = format_duration(summary.energy_now / summary.power_now)
                elseif summary.status == "Charging" and summary.energy_now and summary.energy_full and summary.energy_full > summary.energy_now then
                    duration_label = "充满"
                    duration_value = format_duration((summary.energy_full - summary.energy_now) / summary.power_now)
                end
            elseif summary.current_now and summary.current_now > 0 and summary.charge_now then
                if summary.status == "Discharging" then
                    duration_label = "剩余"
                    duration_value = format_duration(summary.charge_now / summary.current_now)
                elseif summary.status == "Charging" and summary.charge_full and summary.charge_full > summary.charge_now then
                    duration_label = "充满"
                    duration_value = format_duration((summary.charge_full - summary.charge_now) / summary.current_now)
                end
            end

            battery_tooltip_text = battery_label
                .. "\n状态：" .. translate_battery_status(summary.status)
                .. "\n电量：" .. (summary.capacity and (summary.capacity .. "%") or "N/A")

            if summary.count > 1 then
                battery_tooltip_text = battery_tooltip_text .. "\n电池：" .. summary.count .. " 块"
            end

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
            local snapshots = {}
            for _, battery_path in ipairs(battery_paths) do
                local snapshot = collect_battery_snapshot(battery_path)
                if snapshot and snapshot.capacity ~= nil then
                    snapshots[#snapshots + 1] = snapshot
                end
            end

            local summary = aggregate_battery_readings(snapshots)
            if not summary then
                battery_widget:set_markup(render_metric_markup(battery_label, "N/A", ctpp.overlay1))
                battery_tooltip_text = battery_label .. "\n状态：未知\n电量：N/A"
                return
            end

            local capacity = summary.capacity
            local status = summary.status
            local color = ctpp.subtext0
            if status == "Charging" then
                color = ctpp.green
            elseif capacity and capacity <= 15 then
                color = ctpp.red
            elseif capacity and capacity <= 35 then
                color = ctpp.yellow
            elseif not capacity then
                color = ctpp.overlay1
            end

            battery_widget:set_markup(render_metric_markup(battery_label, capacity and tostring(capacity) or "N/A", color))
            update_battery_tooltip(summary)
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
        cpu_widget,
        mem_widget,
    }

    local system_row = wibox.layout.fixed.horizontal()
    system_row.spacing = dpi(4)
    for _, item in ipairs(system_items) do
        system_row:add(item)
    end

    -- System info container
    local sysinfo_widget = wibox.widget {
        system_row,
        left = dpi(2),
        right = dpi(2),
        top = dpi(2),
        bottom = dpi(2),
        widget = wibox.container.margin,
    }

    local function dispose()
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
    find_battery_paths = find_battery_paths,
    aggregate_battery_status = aggregate_battery_status,
    aggregate_battery_readings = aggregate_battery_readings,
    format_speed = format_speed,
    stop_timer = stop_timer,
}

return M
