-- Volume widget using pactl
-- Only used on systems with pulseaudio/pipewire

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local function parse_volume_percent(output)
    if not output then
        return nil
    end

    return output:match("(%d+)%%")
end

local function parse_mute_state(output)
    if not output then
        return nil
    end

    if output:match("%f[%a]yes%f[%A]") then
        return true
    end

    if output:match("%f[%a]no%f[%A]") then
        return false
    end

    return nil
end

local function create_volume_widget(options)
    local ctpp = beautiful.ctpp
    local compact = options and options.compact
    local volume_label = compact and "V" or "VOL"

    local function render_unavailable_markup()
        return "<span foreground='" .. ctpp.yellow .. "'>" .. volume_label .. ":</span><span foreground='" .. ctpp.overlay1 .. "'>N/A</span>"
    end

    local vol_widget = wibox.widget.textbox()
    local volume_tooltip_status = volume_label .. ": N/A"
    local last_volume
    local last_muted
    vol_widget:set_markup(render_unavailable_markup())

    local function render_volume_markup(volume, muted)
        if muted then
            return "<span foreground='" .. ctpp.yellow .. "'>" .. volume_label .. ":</span><span foreground='" .. ctpp.red .. "'>MUTE</span>"
        end

        if volume and volume ~= "" then
            return "<span foreground='" .. ctpp.yellow .. "'>" .. volume_label .. ":</span><span foreground='" .. ctpp.text .. "'>" .. volume .. "%</span>"
        end

        return render_unavailable_markup()
    end

    local function set_volume_tooltip_status(volume, muted)
        if not volume and muted == nil then
            volume_tooltip_status = volume_label .. ": N/A"
            return
        end

        if muted then
            volume_tooltip_status = volume_label .. ": MUTE"
            return
        end

        if volume and volume ~= "" then
            volume_tooltip_status = volume_label .. ": " .. volume .. "%"
            return
        end

        volume_tooltip_status = volume_label .. ": N/A"
    end

    local function remember_volume_state(volume, muted)
        if volume and volume ~= "" then
            last_volume = volume
        end

        if muted ~= nil then
            last_muted = muted
        end
    end

    local function apply_volume_state(volume, muted)
        if not volume and muted == nil then
            vol_widget:set_markup(render_unavailable_markup())
            set_volume_tooltip_status(nil, nil)
            return
        end

        if not volume and muted == false then
            vol_widget:set_markup(render_unavailable_markup())
            set_volume_tooltip_status(nil, nil)
            return
        end

        remember_volume_state(volume, muted)
        vol_widget:set_markup(render_volume_markup(volume, muted))
        set_volume_tooltip_status(volume, muted)
    end

    local function apply_optimistic_mute_toggle()
        local next_muted = true

        if last_muted ~= nil then
            next_muted = not last_muted
        end

        remember_volume_state(last_volume, next_muted)
        vol_widget:set_markup(render_volume_markup(last_volume, next_muted))
        set_volume_tooltip_status(last_volume, next_muted)
    end

    awful.tooltip {
        objects = { vol_widget },
        timer_function = function()
            return volume_tooltip_status
                .. "\n左键：静音切换"
                .. "\n右键：打开音量控制"
                .. "\n滚轮：调整音量"
        end,
    }

    local function update_volume()
        awful.spawn.easy_async_with_shell(
            "LC_ALL=C; export LC_ALL; volume_output=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null || true); mute_output=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null || true); printf '%s\\n__MUTE__\\n%s' \"$volume_output\" \"$mute_output\"",
            function(out)
                local volume_output, mute_output = out:match("^(.-)\n__MUTE__\n(.*)$")
                local volume = parse_volume_percent(volume_output)
                local muted = parse_mute_state(mute_output)

                apply_volume_state(volume, muted)
            end
        )
    end

    local function refresh_after_input_change()
        local refresh_delays = { 0.15, 0.5, 1.2 }

        for _, delay in ipairs(refresh_delays) do
            gears.timer.start_new(delay, function()
                update_volume()
                return false
            end)
        end
    end

    local function run_volume_action(command, on_success)
        awful.spawn.easy_async_with_shell(command .. " >/dev/null 2>&1",
            function(_, _, _, exit_code)
                if exit_code ~= 0 then
                    vol_widget:set_markup(render_unavailable_markup())
                    set_volume_tooltip_status(nil, nil)
                    refresh_after_input_change()
                    return
                end

                if on_success then
                    on_success()
                end

                refresh_after_input_change()
            end
        )
    end

    local function open_volume_control()
        awful.spawn.with_shell("command -v pavucontrol >/dev/null 2>&1 && pavucontrol")
    end

    update_volume()
    gears.timer {
        timeout = 2,
        autostart = true,
        callback = update_volume,
    }

    vol_widget:buttons(gears.table.join(
        awful.button({ }, 4, function()
            run_volume_action("pactl set-sink-volume @DEFAULT_SINK@ +5%")
        end),
        awful.button({ }, 5, function()
            run_volume_action("pactl set-sink-volume @DEFAULT_SINK@ -5%")
        end),
        awful.button({ }, 1, function()
            run_volume_action("pactl set-sink-mute @DEFAULT_SINK@ toggle", apply_optimistic_mute_toggle)
        end),
        awful.button({ }, 3, open_volume_control)
    ))

    return vol_widget, update_volume
end

return {
    create = create_volume_widget,
}
