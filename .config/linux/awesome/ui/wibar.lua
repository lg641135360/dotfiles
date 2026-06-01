local awful = require("awful")
local widget_common = require("awful.widget.common")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local tasklist = require("ui.tasklist")
local hidden_windows = require("ui.hidden_windows")
local window_menu = require("ui.window_menu")
local status_area = require("ui.status_area")
local is_compact_screen = assert(status_area.is_compact_screen)

local TAG_DEFINITIONS = {
    {
        icon = "󰇩 ",
        name = "开发",
        description = "终端、编辑器、调试与构建任务。",
    },
    {
        icon = "󰓠 ",
        name = "浏览器",
        description = "浏览器、网页检索与在线工作流。",
    },
    {
        icon = " ",
        name = "文档",
        description = "资料阅读、PDF、笔记与文档整理。",
    },
    {
        icon = "󰠮 ",
        name = "沟通",
        description = "IM、会议与即时协作。",
    },
    {
        icon = " ",
        name = "杂项",
        description = "临时工具、文件处理与未归类窗口。",
    },
}

local function tag_definition(tag)
    if not tag or not tag.screen or not tag.screen.tags then
        return nil
    end

    for index, candidate in ipairs(tag.screen.tags) do
        if candidate == tag then
            return TAG_DEFINITIONS[index]
        end
    end

    return nil
end

local function tag_display_name(tag)
    local definition = tag_definition(tag)
    if definition and definition.name then
        return definition.name
    end

    return tag and tag.name or "untitled"
end

local M = {}

local function tag_icons()
    local icons = {}
    for _, definition in ipairs(TAG_DEFINITIONS) do
        icons[#icons + 1] = definition.icon
    end
    return icons
end

local function create_lock_button(ctpp, actions)
    local lock = actions.lock or function() end

    local lock_button = wibox.widget {
        {
            markup = "<span foreground='" .. ctpp.yellow .. "'> 󰷛 </span>",
            widget = wibox.widget.textbox,
        },
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

local excluded_tag_tooltip_client_types = {
    desktop = true,
    dock = true,
    splash = true,
}

local function xml_escape(text)
    return gears.string.xml_escape(tostring(text or ""))
end

local function tag_clients(tag)
    if not tag or not tag.clients then
        return {}
    end

    local ok, clients = pcall(function()
        return tag:clients()
    end)
    if ok and clients then
        return clients
    end

    return {}
end

local function is_regular_tag_client(c)
    return c
        and c.valid ~= false
        and not c.skip_taskbar
        and not excluded_tag_tooltip_client_types[c.type]
end

local function tag_has_regular_client(tag)
    for _, c in ipairs(tag_clients(tag)) do
        if is_regular_tag_client(c) then
            return true
        end
    end

    return false
end

local function tag_has_urgent_client(tag)
    for _, c in ipairs(tag_clients(tag)) do
        if is_regular_tag_client(c) and c.urgent then
            return true
        end
    end

    return tag and tag.urgent == true or false
end

local function render_tag_markup(tag, ctpp)
    local selected = tag and tag.selected == true
    local occupied = tag_has_regular_client(tag)
    local fg = selected and ctpp.blue or (occupied and ctpp.lavender or ctpp.subtext0)
    local weight = selected and " weight='bold'" or ""

    return "<span foreground='" .. fg .. "'" .. weight .. ">" .. xml_escape(tag and tag.name or "") .. "</span>"
end

local function update_tag_indicator(self, tag, ctpp)
    local indicator = self:get_children_by_id("tag_indicator_role")[1]
    if not indicator then
        return
    end

    local selected = tag and tag.selected == true
    local occupied = tag_has_regular_client(tag)
    local urgent = tag_has_urgent_client(tag)

    indicator.visible = urgent or (occupied and not selected)
    indicator.color = urgent and ctpp.red or ctpp.lavender
end

local function create_taglist_update_function(ctpp)
    return function(w, buttons, _, data, tags, args)
        local function label(tag)
            return render_tag_markup(tag, ctpp), "#00000000", nil, nil, {}
        end

        widget_common.list_update(w, buttons, label, data, tags, args)
    end
end

local function tag_tooltip_text(tag)
    local definition = tag_definition(tag)
    local regular = {}
    local visible_count = 0
    local minimized_count = 0
    local hidden_count = 0
    local urgent_count = 0

    for _, c in ipairs(tag_clients(tag)) do
        if is_regular_tag_client(c) then
            regular[#regular + 1] = c
            if c.urgent then
                urgent_count = urgent_count + 1
            end
            if c.hidden then
                hidden_count = hidden_count + 1
            elseif c.minimized then
                minimized_count = minimized_count + 1
            else
                visible_count = visible_count + 1
            end
        end
    end

    local lines = { "标签", "名称：" .. tag_display_name(tag) }
    if definition and definition.description then
        lines[#lines + 1] = "语义：" .. definition.description
    end
    lines[#lines + 1] = "窗口：" .. #regular
    lines[#lines + 1] = "可见：" .. visible_count .. " / 最小化：" .. minimized_count .. " / 隐藏：" .. hidden_count

    if urgent_count > 0 then
        lines[#lines + 1] = "紧急：" .. urgent_count
    end

    table.sort(regular, function(a, b)
        local a_name = a.name or a.class or a.instance or "untitled"
        local b_name = b.name or b.class or b.instance or "untitled"
        return a_name < b_name
    end)

    for index, c in ipairs(regular) do
        if index > 5 then
            lines[#lines + 1] = "……"
            break
        end

        local title = c.name or c.class or c.instance or "untitled"
        local state = {}
        if c.urgent then
            state[#state + 1] = "紧急"
        end
        if c.hidden then
            state[#state + 1] = "隐藏"
        elseif c.minimized then
            state[#state + 1] = "最小化"
        end

        if #state > 0 then
            lines[#lines + 1] = index .. ". " .. title .. "（" .. table.concat(state, " / ") .. "）"
        else
            lines[#lines + 1] = index .. ". " .. title
        end
    end

    return table.concat(lines, "\n")
end

local function materialize_widget(widget)
    if not widget then
        return nil
    end

    if widget.fit then
        return widget
    end

    local count = count_sequence_items(widget)
    local ok, realized = pcall(function()
        return wibox.widget(widget)
    end)
    if not ok or not realized then
        return widget
    end

    pcall(function()
        realized._omx_sequence_count = count
    end)
    return realized
end

local function sequence_item_count(widget)
    local ok, count = pcall(function()
        return widget and widget._omx_sequence_count
    end)
    if ok and count ~= nil then
        return count
    end

    return count_sequence_items(widget)
end

local function widget_fit_size(widget, width, height, target_screen)
    local fit_widget = materialize_widget(widget)
    if not fit_widget or not fit_widget.fit then
        return 0, 0
    end

    local ok, fit_width, fit_height = pcall(function()
        return fit_widget:fit({ screen = target_screen }, width, height)
    end)

    if not ok then
        return 0, 0
    end

    return tonumber(fit_width) or 0, tonumber(fit_height) or 0
end

local function tasklist_available_width(s, left_widgets, hidden_indicator, right_widgets)
    local screen_width = s and s.geometry and s.geometry.width or 0
    local probe_height = s and s.mywibox and s.mywibox.height or dpi(40)
    local left_width = select(1, widget_fit_size(left_widgets, screen_width, probe_height, s))
    local right_width = select(1, widget_fit_size(right_widgets, screen_width, probe_height, s))
    local hidden_width = 0

    if hidden_indicator and hidden_indicator.visible ~= false then
        hidden_width = select(1, widget_fit_size(hidden_indicator, screen_width, probe_height, s))
    end

    local floating_chrome_width = dpi(32)
    local task_cluster_spacing = hidden_width > 0 and dpi(4) or 0

    return math.max(screen_width - left_width - right_width - hidden_width - floating_chrome_width - task_cluster_spacing, 0)
end

local function update_wibar_probe_state(s, left_widgets, tasklist_widget, right_widgets, config)
    local function snapshot()
        local screen_width = s and s.geometry and s.geometry.width or 0
        local screen_height = s and s.geometry and s.geometry.height or 0
        local probe_height = s.mywibox and s.mywibox.height or dpi(40)
        local left_width = select(1, widget_fit_size(left_widgets, screen_width, probe_height, s))
        local right_width = select(1, widget_fit_size(right_widgets, screen_width, probe_height, s))
        local tasklist_width = select(1, widget_fit_size(tasklist_widget, math.max(screen_width - left_width - right_width, 0), probe_height, s))

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
            left_item_count = sequence_item_count(left_widgets),
            right_item_count = sequence_item_count(right_widgets),
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
        awful.button({}, 3, function(c)
            local target_screen = c and c.screen or awful.screen.focused()
            window_menu.show_current_tag_menu(target_screen)
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

        s.myhiddenwindows = s.myhiddenwindows or hidden_windows.create_indicator(ctpp, s)
        if s.myhiddenwindows.update then
            s.myhiddenwindows:update()
        end

        local compact = is_compact_screen(s, config)
        local clock_widget = s.mytextclock
        local right_widget_data = status_area.create_right_widgets(config, ctpp, s, clock_widget)
        local right_widgets = materialize_widget(right_widget_data.right_widgets)
        local left_widgets = materialize_widget(build_left_widgets(s))
        local available_tasklist_width = tasklist_available_width(s, left_widgets, s.myhiddenwindows, right_widgets)
        local desired_tasklist_width = tasklist.task_title_max_width(s, config, compact, available_tasklist_width)
        if not s.mytasklist
            or s.mytasklist_width ~= desired_tasklist_width
            or s.mytasklist_available_width ~= available_tasklist_width then
            s.mytasklist = tasklist.create_tasklist(ctpp, s, tasklist_buttons, config, compact, available_tasklist_width)
            s.mytasklist_width = desired_tasklist_width
            s.mytasklist_available_width = available_tasklist_width
        end
        local task_cluster = materialize_widget {
            s.mytasklist,
            s.myhiddenwindows,
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(4),
        }

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

    if client and client.connect_signal then
        for _, signal in ipairs({
            "property::minimized",
            "property::hidden",
            "property::skip_taskbar",
            "property::screen",
            "tagged",
            "untagged",
            "manage",
            "unmanage",
            "list",
        }) do
            client.connect_signal(signal, queue_wibar_refresh)
        end
    end

    awful.screen.connect_for_each_screen(function(s)
        awful.tag(tag_icons(), s, awful.layout.layouts[1])
        awful.tag.attached_connect_signal(s, "property::selected", queue_wibar_refresh)

        s.mypromptbox = awful.widget.prompt()
        s.mylayoutbox = create_layoutbox(ctpp, s)
        s.mylockbutton = create_lock_button(ctpp, actions)
        s.mytaglist = awful.widget.taglist {
            screen = s,
            filter = awful.widget.taglist.filter.all,
            buttons = taglist_buttons,
            update_function = create_taglist_update_function(ctpp),
            widget_template = {
                {
                    {
                        {
                            id = "text_role",
                            widget = wibox.widget.textbox,
                        },
                        left = 8,
                        right = 8,
                        widget = wibox.container.margin,
                    },
                    {
                        {
                            id = "tag_indicator_role",
                            forced_width = dpi(6),
                            forced_height = dpi(6),
                            color = ctpp.lavender,
                            shape = gears.shape.circle,
                            visible = false,
                            widget = wibox.widget.separator,
                        },
                        halign = "right",
                        valign = "top",
                        widget = wibox.container.place,
                    },
                    layout = wibox.layout.stack,
                },
                id = "background_role",
                widget = wibox.container.background,
                create_callback = function(self, tag)
                    self._tag_tooltip_text = tag_tooltip_text(tag)
                    update_tag_indicator(self, tag, ctpp)
                    if not self._tag_tooltip then
                        self._tag_tooltip = awful.tooltip {
                            objects = { self },
                            timer_function = function()
                                return self._tag_tooltip_text or ""
                            end,
                        }
                    end
                end,
                update_callback = function(self, tag)
                    self._tag_tooltip_text = tag_tooltip_text(tag)
                    update_tag_indicator(self, tag, ctpp)
                end,
            },
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
        s.myhiddenwindows = nil
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
    task_title_max_width = function(s, config, available_width)
        return tasklist.task_title_max_width(s, config, is_compact_screen(s, config), available_width)
    end,
    tasklist_available_width = tasklist_available_width,
    widget_fit_size = widget_fit_size,
}

return M
