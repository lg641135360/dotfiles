local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

local function output_diagonal_inches(output)
    if not output then
        return nil
    end

    local mm_width = tonumber(output.mm_width)
    local mm_height = tonumber(output.mm_height)

    if not mm_width or not mm_height or mm_width <= 0 or mm_height <= 0 then
        return nil
    end

    return math.sqrt(mm_width * mm_width + mm_height * mm_height) / 25.4
end

local function screen_diagonal_inches(screen)
    if not screen or not screen.outputs then
        return nil
    end

    local max_diagonal = nil

    for _, output in pairs(screen.outputs) do
        local diagonal = output_diagonal_inches(output)
        if diagonal and (not max_diagonal or diagonal > max_diagonal) then
            max_diagonal = diagonal
        end
    end

    return max_diagonal
end

local function is_compact_screen(screen, config)
    local max_diagonal_inches = (config and config.compact_wibar_max_diagonal_inches) or 15
    local diagonal_inches = screen_diagonal_inches(screen)
    if diagonal_inches then
        return diagonal_inches <= max_diagonal_inches
    end

    local max_width = (config and config.compact_wibar_max_width) or 3000
    return screen and screen.geometry and screen.geometry.width <= max_width
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

local function create_textclock(ctpp, config, screen)
    local textclock = wibox.widget.textbox()
    local clock_h_padding = is_compact_screen(screen, config) and 5 or 6
    local clock_v_padding = is_compact_screen(screen, config) and 1 or 2
    local weekdays = {
        "星期日",
        "星期一",
        "星期二",
        "星期三",
        "星期四",
        "星期五",
        "星期六",
    }

    local function render_clock_tooltip()
        local now = os.date("*t")
        local weekday = weekdays[now.wday] or ""

        return "时间"
            .. "\n日期：" .. os.date("%Y-%m-%d")
            .. "\n星期：" .. weekday
            .. "\n当前：" .. os.date("%H:%M")
    end

    local function update_clock()
        local date_format = config.date_format
        if is_compact_screen(screen, config) and config.compact_date_format then
            date_format = config.compact_date_format
        end

        local time_str = os.date(date_format)
        textclock:set_markup("<span foreground='" .. ctpp.lavender .. "'>" .. time_str .. "</span>")
    end

    local clock_timer = gears.timer {
        timeout = 60,
        autostart = true,
        call_now = true,
        callback = update_clock,
    }

    local clock_widget = wibox.widget {
        {
            textclock,
            left = clock_h_padding,
            right = clock_h_padding,
            top = clock_v_padding,
            bottom = clock_v_padding,
            widget = wibox.container.margin,
        },
        bg = ctpp.mantle,
        border_width = dpi(1),
        border_color = ctpp.surface1,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background,
    }

    awful.tooltip {
        objects = { clock_widget },
        timer_function = function()
            return render_clock_tooltip()
        end,
    }

    local function dispose()
        stop_timer(clock_timer)
    end

    clock_widget._refresh = update_clock
    clock_widget._dispose = dispose

    return clock_widget
end

local function create_systray_widget(ctpp)
    local systray = wibox.widget.systray()
    systray:set_base_size(dpi(20))

    return wibox.widget {
        {
            {
                systray,
                valign = "center",
                widget = wibox.container.place,
            },
            left = 4,
            right = 4,
            top = 2,
            bottom = 2,
            widget = wibox.container.margin,
        },
        bg = ctpp.mantle,
        border_width = dpi(1),
        border_color = ctpp.surface1,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background,
    }
end

local function create_separator(ctpp)
    return wibox.widget {
        markup = "<span foreground='" .. ctpp.surface1 .. "'>│</span>",
        widget = wibox.widget.textbox,
    }
end

local function create_sysinfo_bundle(config, screen, compact)
    compact = compact == nil and is_compact_screen(screen, config) or compact
    local system_widgets = require("widgets.system").create(config, {
        compact = compact,
    })
    local sysinfo_widget = system_widgets.sysinfo_widget
    local system_row = system_widgets.system_row
    local make_separator = system_widgets.make_separator
    local brightness_bundle = nil
    local volume_bundle = nil

    if config.has_brightness then
        brightness_bundle = require("widgets.brightness").create({
            compact = compact,
        })
    end

    if brightness_bundle then
        system_row:add(make_separator())
        system_row:add(brightness_bundle.widget)
    end

    if config.has_volume then
        volume_bundle = require("widgets.volume").create({
            compact = compact,
        })
        system_row:add(make_separator())
        system_row:add(volume_bundle.widget)
    end

    local function dispose()
        if brightness_bundle and brightness_bundle.dispose then
            brightness_bundle.dispose()
        end
        if volume_bundle and volume_bundle.dispose then
            volume_bundle.dispose()
        end
        if system_widgets.dispose then
            system_widgets.dispose()
        end
    end

    return {
        sysinfo_widget = sysinfo_widget,
        make_separator = make_separator,
        compact = compact,
        dispose = dispose,
    }
end

local function dispose_status_widgets(s)
    if s.mystatusbundle and s.mystatusbundle.dispose then
        s.mystatusbundle.dispose()
    end
    s.mystatusbundle = nil
    s.mystatusspec = nil
    s.mysystray_widget = nil
end

local function ensure_primary_status_widgets(config, ctpp, s, compact)
    local spec = table.concat({
        compact and "compact" or "full",
        config.has_volume and "vol" or "novol",
        config.has_brightness and "bri" or "nobri",
    }, ":")
    if s.mystatusbundle and s.mystatusspec == spec then
        return s.mystatusbundle
    end

    dispose_status_widgets(s)

    local system_bundle = create_sysinfo_bundle(config, s, compact)
    s.mysystray_widget = s.mysystray_widget or create_systray_widget(ctpp)
    s.mystatusbundle = {
        sysinfo_widget = system_bundle.sysinfo_widget,
        systray_widget = s.mysystray_widget,
        dispose = system_bundle.dispose,
    }
    s.mystatusspec = spec
    return s.mystatusbundle
end

local function create_right_widgets(config, ctpp, target_screen, clock_widget)
    local compact = is_compact_screen(target_screen, config)
    local right_widgets = {
        layout = wibox.layout.fixed.horizontal,
        spacing = compact and 2 or 4,
    }

    if target_screen == screen.primary then
        local status_bundle = ensure_primary_status_widgets(config, ctpp, target_screen, compact)
        local sysinfo_widget = status_bundle.sysinfo_widget
        local systray_widget = status_bundle.systray_widget

        table.insert(right_widgets, sysinfo_widget)
        table.insert(right_widgets, create_separator(ctpp))
        table.insert(right_widgets, {
            systray_widget,
            left = 1,
            right = 1,
            widget = wibox.container.margin,
        })
        table.insert(right_widgets, create_separator(ctpp))
    else
        dispose_status_widgets(target_screen)
    end

    table.insert(right_widgets, {
        clock_widget,
        left = 0,
        right = compact and 1 or 3,
        widget = wibox.container.margin,
    })

    return {
        right_widgets = right_widgets,
        compact = compact,
    }
end

return {
    is_compact_screen = is_compact_screen,
    create_separator = create_separator,
    create_textclock = create_textclock,
    create_right_widgets = create_right_widgets,
    dispose_status_widgets = dispose_status_widgets,
}
