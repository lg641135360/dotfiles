-- System info widgets: CPU, MEM, NET
-- Returns a container with all system widgets and helper functions

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local function create_system_widgets(config)
    local ctpp = beautiful.ctpp
    local dpi = require("beautiful.xresources").apply_dpi

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

    -- CPU widget
    local cpu_widget = wibox.widget.textbox()
    cpu_widget:set_markup("<span foreground='" .. ctpp.blue .. "'>CPU</span><span foreground='" .. ctpp.text .. "'> 0%</span>")

    -- Memory widget
    local mem_widget = wibox.widget.textbox()
    mem_widget:set_markup("<span foreground='" .. ctpp.green .. "'>MEM</span><span foreground='" .. ctpp.text .. "'> 0%</span>")

    -- Network widget
    local net_widget = wibox.widget.textbox()
    net_widget:set_markup("<span foreground='" .. ctpp.teal .. "'>NET</span><span foreground='" .. ctpp.text .. "'> 0K 0K</span>")

    -- Battery widget (laptops only)
    local battery_widget = nil
    local battery_path = find_battery_path()
    if battery_path then
        battery_widget = wibox.widget.textbox()
        battery_widget:set_markup("<span foreground='" .. ctpp.yellow .. "'>BAT</span><span foreground='" .. ctpp.text .. "'> 0%</span>")
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
            cpu_widget:set_markup("<span foreground='" .. ctpp.blue .. "'>CPU</span><span foreground='" .. color .. "'> " .. cpu_now.usage .. "%</span>")
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
            mem_widget:set_markup("<span foreground='" .. ctpp.green .. "'>MEM</span><span foreground='" .. color .. "'> " .. mem_now.perc .. "%</span>")
        end,
    }

    -- Network monitoring
    local net_prev = { recv = 0, sent = 0 }

    local function format_speed(bytes_per_sec)
        if bytes_per_sec < 1024 then
            return string.format("%.0fB", bytes_per_sec)
        elseif bytes_per_sec < 1024 * 1024 then
            return string.format("%.1fK", bytes_per_sec / 1024)
        else
            return string.format("%.1fM", bytes_per_sec / 1024 / 1024)
        end
    end

    local function update_net()
        local f = io.popen("cat /proc/net/dev | grep -E '" .. config.net_interfaces .. "' | head -1 | awk '{printf(\"%d %d\", $2, $10)}'")
        if f then
            local result = f:read("*a"):gsub("\n", "")
            f:close()
            if result and result ~= "" then
                local recv, sent = result:match("(%d+) (%d+)")
                if recv and sent then
                    recv = tonumber(recv)
                    sent = tonumber(sent)
                    local recv_speed = (recv - net_prev.recv) / 2
                    local sent_speed = (sent - net_prev.sent) / 2

                    net_widget:set_markup("<span foreground='" .. ctpp.teal .. "'>NET</span><span foreground='" .. ctpp.blue .. "'> ↓" .. format_speed(recv_speed) .. "</span> <span foreground='" .. ctpp.peach .. "'>↑" .. format_speed(sent_speed) .. "</span>")
                    net_prev.recv = recv
                    net_prev.sent = sent
                end
            end
        end
    end

    update_net()
    gears.timer {
        timeout = 2,
        autostart = true,
        callback = update_net,
    }

    if battery_widget then
        local function update_battery()
            local capacity = tonumber(read_file(battery_path .. "/capacity"))
            if not capacity then
                return
            end

            local color = ctpp.text
            if capacity <= 15 then
                color = ctpp.red
            elseif capacity <= 35 then
                color = ctpp.yellow
            end

            battery_widget:set_markup("<span foreground='" .. ctpp.yellow .. "'>BAT</span><span foreground='" .. color .. "'> " .. capacity .. "%</span>")
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
            markup = "<span foreground='" .. ctpp.surface2 .. "'>│</span>",
            widget = wibox.widget.textbox,
        }
    end

    local system_items = {
        cpu_widget,
        make_separator(),
        mem_widget,
        make_separator(),
        net_widget,
    }

    if battery_widget then
        table.insert(system_items, make_separator())
        table.insert(system_items, battery_widget)
    end

    local system_row = wibox.layout.fixed.horizontal()
    system_row.spacing = 8
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
        left = 8,
        right = 8,
        top = 4,
        bottom = 4,
        widget = wibox.container.margin,
    }

    return {
        sysinfo_widget = sysinfo_widget,
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
