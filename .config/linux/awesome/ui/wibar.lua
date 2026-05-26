local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local tasklist = require("ui.tasklist")
local status_area = require("ui.status_area")
local is_compact_screen = assert(status_area.is_compact_screen)

local M = {}

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

local function create_floating_wibar_content(ctpp, left_widgets, task_cluster, right_widgets)
    local content = wibox.widget {
        layout = wibox.layout.align.horizontal,
        left_widgets,
        task_cluster,
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

local function setup_floating_wibar(s, ctpp, left_widgets, task_cluster, right_widgets)
    local floating_content = create_floating_wibar_content(ctpp, left_widgets, task_cluster, right_widgets)

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
            table.insert(left_widgets, status_area.create_separator(ctpp))
            table.insert(left_widgets, s.mypromptbox)
        end

        return left_widgets
    end

    local function rebuild_screen_wibar(s)
        if not s.mytextclock then
            local clock_widget = status_area.create_textclock(ctpp, config, s)
            s.mytextclock = clock_widget
        elseif s.mytextclock._refresh then
            s.mytextclock._refresh()
        end

        local desired_tasklist_width = tasklist.task_title_max_width(s, config, is_compact_screen(s, config))
        if not s.mytasklist or s.mytasklist_width ~= desired_tasklist_width then
            s.mytasklist = tasklist.create_tasklist(ctpp, s, tasklist_buttons, config, is_compact_screen(s, config))
            s.mytasklist_width = desired_tasklist_width
        end
        s.mytaskoverflow = s.mytaskoverflow or tasklist.create_overflow_indicator(ctpp, s)

        local task_cluster = {
            s.mytasklist,
            s.mytaskoverflow,
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(4),
        }

        local clock_widget = s.mytextclock
        local right_widget_data = status_area.create_right_widgets(config, ctpp, s, clock_widget)
        local right_widgets = right_widget_data.right_widgets
        local left_widgets = build_left_widgets(s)
        local screen_width = s and s.geometry and s.geometry.width or 0
        local probe_height = s.mywibox and s.mywibox.height or dpi(40)
        local left_width = select(1, widget_fit_size(left_widgets, screen_width, probe_height))
        local right_width = select(1, widget_fit_size(right_widgets, screen_width, probe_height))

        local available_width = math.max(screen_width - left_width - right_width, 0)
        s._omx_task_available_width = available_width

        if s.mytaskoverflow.update then
            s.mytaskoverflow:update(available_width)
        end

        setup_floating_wibar(s, ctpp, left_widgets, task_cluster, right_widgets)
        update_wibar_probe_state(s, left_widgets, task_cluster, right_widgets, config)
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
        status_area.dispose_status_widgets(s)
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
    is_compact_screen = is_compact_screen,
    task_title_max_width = function(s, config)
        return tasklist.task_title_max_width(s, config, is_compact_screen(s, config))
    end,
}

return M
