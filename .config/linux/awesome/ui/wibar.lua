local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

local xml_escape = gears.string.xml_escape

local function render_task_text(c, ctpp)
    local name = xml_escape(c.name or "")

    if name == "" then
        name = "untitled"
    end

    if c.minimized then
        return '<span color="' .. ctpp.overlay2 .. '">[min] ' .. name .. '</span>'
    end

    if client and c == client.focus then
        return '<span foreground="' .. ctpp.blue .. '"><b>' .. name .. '</b></span>'
    end

    return '<span foreground="' .. ctpp.text .. '">' .. name .. '</span>'
end

local function render_task_tooltip(c)
    local title = c.name or "untitled"
    local app_name = c.class or c.instance
    local lines = { "窗口", "标题：" .. title }

    if app_name and app_name ~= "" then
        lines[#lines + 1] = "应用：" .. app_name
    end

    if c.minimized then
        lines[#lines + 1] = "状态：最小化"
    elseif c.urgent then
        lines[#lines + 1] = "状态：紧急"
    end

    return table.concat(lines, "\n")
end

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

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

local function task_title_max_width(screen, config)
    local compact = is_compact_screen(screen, config)
    local screen_width = screen and screen.geometry and screen.geometry.width or 1920
    local ratio = compact and 0.12 or 0.16
    local min_width = compact and 220 or 320
    local max_width = compact and 360 or 640
    local computed_width = math.floor((screen_width * ratio) + 0.5)
    return dpi(clamp(computed_width, min_width, max_width))
end

local function update_task_item(self, c, ctpp, screen, config)
    local img = self:get_children_by_id("icon_role")[1]
    if img then
        img.forced_width = dpi(20)
        img.forced_height = dpi(20)
    end

    local text_constraint = self:get_children_by_id("text_constraint_role")[1]
    if text_constraint then
        text_constraint.width = task_title_max_width(screen, config)
    end

    local text = self:get_children_by_id("text_role")[1]
    if text then
        text.markup = render_task_text(c, ctpp)
    end

    local focused = client and c == client.focus
    local urgent = c.urgent
    local background = self:get_children_by_id("background_role")[1]
    if background then
        background.bg = focused and ctpp.surface0 or ctpp.base
    end

    local indicator = self:get_children_by_id("focus_indicator_role")[1]
    if indicator then
        indicator.bg = urgent and ctpp.red or (focused and ctpp.blue or ctpp.base)
    end
end

local function create_lock_button(ctpp, actions)
    local lock = actions.lock or function() end

    local lock_button = wibox.widget {
        {
            markup = "<span foreground='" .. ctpp.yellow .. "'> 󰷛 </span>",
            widget = wibox.widget.textbox,
        },
        bg = ctpp.surface0,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(6))
        end,
        left = 8,
        right = 8,
        top = 4,
        bottom = 4,
        widget = wibox.container.margin,
    }

    lock_button:buttons(gears.table.join(
        awful.button({ }, 1, lock)
    ))

    awful.tooltip {
        objects = { lock_button },
        timer_function = function()
            return "锁屏\n操作：立即锁屏\n快捷键：Super+Shift+L"
        end,
    }

    return lock_button
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
    local volume_bundle = nil

    if config.has_volume then
        volume_bundle = require("widgets.volume").create({
            compact = compact,
        })
        system_row:add(make_separator())
        system_row:add(volume_bundle.widget)
    end

    local function dispose()
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
    local spec = (compact and "compact" or "full") .. ":" .. (config.has_volume and "vol" or "novol")
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
            right = compact and 2 or 4,
            widget = wibox.container.margin,
        })

    return {
        right_widgets = right_widgets,
        compact = compact,
    }
end

local function create_layoutbox(ctpp, screen)
    local mylayoutbox_widget = wibox.widget {
        markup = " [M] ",
        widget = wibox.widget.textbox,
    }

    local layout_label = {
        tileleft = "左侧平铺",
        max = "最大化",
    }

    local layoutbox = wibox.widget {
        mylayoutbox_widget,
        bg = ctpp.surface0,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(6))
        end,
        left = 4,
        right = 4,
        top = 2,
        bottom = 2,
        widget = wibox.container.margin,
    }

    local function update_layoutbox()
        local layout_name = awful.layout.getname(awful.layout.get(screen))
        local layout_text = {
            tileleft = "[]=",
            tilebottom = "TTT",
            tiletop = "┬┬┬",
            fairh = "═══",
            fairv = "|||",
            floating = "><>",
            max = "[M]",
            tile = "[]=",
            fullscreen = "[ ]",
            magnifier = "[+]",
            spiral = "[@]",
            dwindle = "[\\]",
            cornernw = "┌─┐",
            cornerne = "┌─┐",
            cornersw = "└─┘",
            cornerse = "└─┘",
        }
        mylayoutbox_widget.markup = " <span foreground='" .. ctpp.mauve .. "'> " .. (layout_text[layout_name] or layout_name) .. " </span>"
    end

    update_layoutbox()
    awful.tag.attached_connect_signal(screen, "property::selected", update_layoutbox)
    awful.tag.attached_connect_signal(screen, "property::layout", update_layoutbox)

    awful.tooltip {
        objects = { layoutbox },
        timer_function = function()
            local layout_name = awful.layout.getname(awful.layout.get(screen))
            return "布局\n当前：" .. (layout_label[layout_name] or layout_name)
                .. "\n左键/右键/滚轮：切换布局"
        end,
    }

    layoutbox:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.layout.inc(1)
            update_layoutbox()
        end),
        awful.button({}, 3, function()
            awful.layout.inc(-1)
            update_layoutbox()
        end),
        awful.button({}, 4, function()
            awful.layout.inc(1)
            update_layoutbox()
        end),
        awful.button({}, 5, function()
            awful.layout.inc(-1)
            update_layoutbox()
        end)
    ))

    return layoutbox
end

local function create_tasklist(ctpp, screen, tasklist_buttons, config)
    local item_spacing = is_compact_screen(screen, config) and 4 or 6
    local item_h_padding = is_compact_screen(screen, config) and 6 or 8
    local item_v_padding = is_compact_screen(screen, config) and 1 or 2
    return awful.widget.tasklist {
        screen = screen,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout = {
            spacing = dpi(3),
            layout = wibox.layout.fixed.horizontal,
        },
        widget_template = {
            {
                {
                    {
                        id = "focus_indicator_role",
                        forced_width = dpi(3),
                        widget = wibox.container.background,
                    },
                    {
                        {
                            id = "icon_role",
                            widget = wibox.widget.imagebox,
                        },
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    {
                        {
                            id = "text_role",
                            ellipsize = "end",
                            widget = wibox.widget.textbox,
                        },
                        id = "text_constraint_role",
                        strategy = "max",
                        width = task_title_max_width(screen, config),
                        widget = wibox.container.constraint,
                    },
                    spacing = item_spacing,
                    layout = wibox.layout.fixed.horizontal,
                },
                left = item_h_padding,
                right = item_h_padding,
                top = item_v_padding,
                bottom = item_v_padding,
                widget = wibox.container.margin,
            },
            id = "background_role",
            bg = ctpp.base,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, dpi(7))
            end,
            widget = wibox.container.background,
            create_callback = function(self, c)
                self._task_tooltip_text = render_task_tooltip(c)
                if not self._task_tooltip then
                    self._task_tooltip = awful.tooltip {
                        objects = { self },
                        timer_function = function()
                            return self._task_tooltip_text or ""
                        end,
                    }
                end
                update_task_item(self, c, ctpp, screen, config)
            end,
            update_callback = function(self, c)
                self._task_tooltip_text = render_task_tooltip(c)
                update_task_item(self, c, ctpp, screen, config)
            end,
        },
    }
end

local function create_floating_wibar_content(ctpp, left_widgets, tasklist_widget, right_widgets)
    local content = wibox.widget {
        layout = wibox.layout.align.horizontal,
        left_widgets,
        tasklist_widget,
        right_widgets,
    }

    return wibox.widget {
        {
            content,
            left = dpi(8),
            right = dpi(8),
            top = dpi(4),
            bottom = dpi(4),
            widget = wibox.container.margin,
        },
        bg = ctpp.base,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(12))
        end,
        widget = wibox.container.background,
    }
end

local function setup_floating_wibar(s, ctpp, left_widgets, tasklist_widget, right_widgets)
    local floating_content = create_floating_wibar_content(ctpp, left_widgets, tasklist_widget, right_widgets)

    if not s.mywibox then
        s.mywibox = awful.wibar {
            position = "top",
            screen = s,
            height = dpi(40),
            bg = "#00000000",
        }
    else
        s.mywibox.height = dpi(40)
        s.mywibox.bg = "#00000000"
    end

    s.mywibox:setup {
        floating_content,
        top = dpi(6),
        left = dpi(8),
        right = dpi(8),
        widget = wibox.container.margin,
    }
end

local function count_sequence_items(tbl)
    local count = 0
    for _ in ipairs(tbl or {}) do
        count = count + 1
    end
    return count
end

local function widget_fit_size(widget, width, height)
    if not widget or not widget.fit then
        return 0, 0
    end

    local ok, fit_width, fit_height = pcall(function()
        return widget:fit({}, width, height)
    end)

    if not ok then
        return 0, 0
    end

    return tonumber(fit_width) or 0, tonumber(fit_height) or 0
end

local function update_wibar_probe_state(s, left_widgets, tasklist_widget, right_widgets, config)
    local function snapshot()
        local screen_width = s and s.geometry and s.geometry.width or 0
        local screen_height = s and s.geometry and s.geometry.height or 0
        local probe_height = s.mywibox and s.mywibox.height or dpi(40)
        local left_width = select(1, widget_fit_size(left_widgets, screen_width, probe_height))
        local right_width = select(1, widget_fit_size(right_widgets, screen_width, probe_height))
        local tasklist_width = select(1, widget_fit_size(tasklist_widget, math.max(screen_width - left_width - right_width, 0), probe_height))

        return {
            screen_index = s.index,
            screen_width = screen_width,
            screen_height = screen_height,
            compact = is_compact_screen(s, config),
            is_primary = s == screen.primary,
            left_width = left_width,
            right_width = right_width,
            tasklist_width = tasklist_width,
            tasklist_title_max_width = s.mytasklist_width,
            left_item_count = count_sequence_items(left_widgets),
            right_item_count = count_sequence_items(right_widgets),
            has_tasklist = tasklist_widget ~= nil,
            has_promptbox = s == screen.primary,
            has_systray = s == screen.primary,
        }
    end

    s._omx_wibar_probe = {
        snapshot = snapshot,
        last = snapshot(),
    }
end

function M.setup(args)
    local modkey = args.modkey
    local ctpp = args.ctpp
    local config = args.config
    local actions = args.actions or {}

    local taglist_buttons = gears.table.join(
        awful.button({}, 1, function(t)
            t:view_only()
        end),
        awful.button({ modkey }, 1, function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end),
        awful.button({}, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
        awful.button({}, 4, function(t)
            awful.tag.viewnext(t.screen)
        end),
        awful.button({}, 5, function(t)
            awful.tag.viewprev(t.screen)
        end)
    )

    local tasklist_buttons = gears.table.join(
        awful.button({}, 1, function(c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal("request::activate", "tasklist", { raise = true })
            end
        end),
        awful.button({}, 3, function()
            awful.menu.client_list({ theme = { width = 250 } })
        end),
        awful.button({}, 4, function()
            awful.client.focus.byidx(1)
        end),
        awful.button({}, 5, function()
            awful.client.focus.byidx(-1)
        end)
    )

    local function build_left_widgets(s)
        local left_widgets = {
            layout = wibox.layout.fixed.horizontal,
            spacing = s == screen.primary and dpi(4) or dpi(2),
            {
                s.mytaglist,
                left = 8,
                right = s == screen.primary and 4 or 2,
                widget = wibox.container.margin,
            },
            s.mylayoutbox,
        }

        if s == screen.primary then
            table.insert(left_widgets, s.mylockbutton)
            table.insert(left_widgets, create_separator(ctpp))
            table.insert(left_widgets, s.mypromptbox)
        end

        return left_widgets
    end

    local function rebuild_screen_wibar(s)
        if not s.mytextclock then
            s.mytextclock = create_textclock(ctpp, config, s)
        elseif s.mytextclock._refresh then
            s.mytextclock._refresh()
        end

        local desired_tasklist_width = task_title_max_width(s, config)
        if not s.mytasklist or s.mytasklist_width ~= desired_tasklist_width then
            s.mytasklist = create_tasklist(ctpp, s, tasklist_buttons, config)
            s.mytasklist_width = desired_tasklist_width
        end

        local right_bundle = create_right_widgets(config, ctpp, s, s.mytextclock)
        local right_widgets = right_bundle.right_widgets
        local left_widgets = build_left_widgets(s)

        setup_floating_wibar(s, ctpp, left_widgets, s.mytasklist, right_widgets)
        update_wibar_probe_state(s, left_widgets, s.mytasklist, right_widgets, config)
    end

    local refresh_queued = false
    local function queue_wibar_refresh()
        if refresh_queued then
            return
        end

        refresh_queued = true
        gears.timer.delayed_call(function()
            refresh_queued = false
            for s in screen do
                rebuild_screen_wibar(s)
            end
        end)
    end

    awful.screen.connect_for_each_screen(function(s)
        awful.tag({ "󰇩 ", "󰓠 ", "󰠮 ", " ", " " }, s, awful.layout.layouts[1])

        s.mypromptbox = awful.widget.prompt()
        s.mylayoutbox = create_layoutbox(ctpp, s)
        s.mylockbutton = create_lock_button(ctpp, actions)
        s.mytaglist = awful.widget.taglist {
            screen = s,
            filter = awful.widget.taglist.filter.all,
            buttons = taglist_buttons,
        }

        rebuild_screen_wibar(s)
    end)

    screen.connect_signal("property::geometry", queue_wibar_refresh)
    screen.connect_signal("property::primary", queue_wibar_refresh)
    screen.connect_signal("added", queue_wibar_refresh)
    screen.connect_signal("removed", function(s)
        dispose_status_widgets(s)
        if s.mytextclock and s.mytextclock._dispose then
            s.mytextclock._dispose()
        end
        s._omx_wibar_probe = nil
        queue_wibar_refresh()
    end)
    awesome.connect_signal("screen::change", queue_wibar_refresh)

    return {
        run_prompt = function()
            local promptbox = awful.screen.focused().mypromptbox
            if promptbox then
                promptbox:run()
            end
        end,
        run_lua_prompt = function()
            local promptbox = awful.screen.focused().mypromptbox
            if promptbox and promptbox.widget then
                awful.prompt.run {
                    prompt = "Run Lua code: ",
                    textbox = promptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval",
                }
            end
        end,
    }
end

M._private = {
    output_diagonal_inches = output_diagonal_inches,
    screen_diagonal_inches = screen_diagonal_inches,
    is_compact_screen = is_compact_screen,
    task_title_max_width = task_title_max_width,
}

return M
