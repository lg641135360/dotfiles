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

    if c == client.focus then
        return '<span foreground="' .. ctpp.blue .. '"><b>' .. name .. '</b></span>'
    end

    return '<span foreground="' .. ctpp.text .. '">' .. name .. '</span>'
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

    return lock_button
end

local function is_compact_screen(screen, config)
    local max_width = (config and config.compact_wibar_max_width) or 3000
    return screen and screen.geometry and screen.geometry.width <= max_width
end

local function create_textclock(ctpp, config, screen)
    local textclock = wibox.widget.textbox()

    gears.timer {
        timeout = 60,
        autostart = true,
        call_now = true,
        callback = function()
            local date_format = config.date_format
            if is_compact_screen(screen, config) and config.compact_date_format then
                date_format = config.compact_date_format
            end

            local time_str = os.date(date_format)
            textclock:set_markup("<span foreground='" .. ctpp.lavender .. "'>" .. time_str .. "</span>")
        end
    }

    return textclock
end

local function create_systray_widget(ctpp)
    local systray = wibox.widget.systray()
    systray:set_base_size(dpi(22))

    return wibox.widget {
        {
            systray,
            valign = "center",
            widget = wibox.container.place,
        },
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
end

local function create_sysinfo_bundle(config, ctpp, lain_ok, screen)
    local compact = is_compact_screen(screen, config)

    if lain_ok then
        local system_widgets = require("widgets.system").create(config, {
            compact = is_compact_screen(screen, config),
        })
        local sysinfo_widget = system_widgets.sysinfo_widget
        local system_row = system_widgets.system_row
        local make_separator = system_widgets.make_separator

        if config.has_volume then
            local vol_widget = require("widgets.volume").create()
            system_row:add(make_separator())
            system_row:add(vol_widget)
        end

        return {
            sysinfo_widget = sysinfo_widget,
            make_separator = make_separator,
            compact = compact,
        }
    end

    return {
        compact = compact,
        sysinfo_widget = wibox.widget {
            markup = "<span foreground='" .. ctpp.overlay0 .. "'>[lain missing]</span>",
            widget = wibox.widget.textbox,
        },
        make_separator = function()
            return wibox.widget { markup = " ", widget = wibox.widget.textbox }
        end,
    }
end

local function create_layoutbox(ctpp, screen)
    local mylayoutbox_widget = wibox.widget {
        markup = " [M] ",
        widget = wibox.widget.textbox,
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

local function create_tasklist(ctpp, screen, tasklist_buttons)
    return awful.widget.tasklist {
        screen = screen,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        widget_template = {
            {
                {
                    {
                        id = "icon_role",
                        widget = wibox.widget.imagebox,
                    },
                    valign = "center",
                    widget = wibox.container.place,
                },
                {
                    id = "text_role",
                    widget = wibox.widget.textbox,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            left = 8,
            right = 8,
            widget = wibox.container.margin,
            create_callback = function(self, c)
                local img = self:get_children_by_id("icon_role")[1]
                if img then
                    img.forced_width = dpi(20)
                    img.forced_height = dpi(20)
                end
                local text = self:get_children_by_id("text_role")[1]
                text.markup = render_task_text(c, ctpp)
            end,
            update_callback = function(self, c)
                local text = self:get_children_by_id("text_role")[1]
                text.markup = render_task_text(c, ctpp)
            end,
        },
    }
end

function M.setup(args)
    local modkey = args.modkey
    local ctpp = args.ctpp
    local config = args.config
    local actions = args.actions or {}
    local lain_ok = args.lain_ok

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

    local primary_systray_widget = create_systray_widget(ctpp)

    awful.screen.connect_for_each_screen(function(s)
        local system_bundle = create_sysinfo_bundle(config, ctpp, lain_ok, s)
        local sysinfo_widget = system_bundle.sysinfo_widget
        local make_separator = system_bundle.make_separator
        local lock_button = create_lock_button(ctpp, actions)
        local compact = system_bundle.compact
        local mytextclock = create_textclock(ctpp, config, s)

        awful.tag({ "󰇩 ", "󰓠 ", "󰠮 ", " ", " " }, s, awful.layout.layouts[1])

        s.mypromptbox = awful.widget.prompt()
        s.mylayoutbox = create_layoutbox(ctpp, s)
        s.mytaglist = awful.widget.taglist {
            screen = s,
            filter = awful.widget.taglist.filter.all,
            buttons = taglist_buttons,
        }
        s.mytasklist = create_tasklist(ctpp, s, tasklist_buttons)

        s.mywibox = awful.wibar {
            position = "top",
            screen = s,
            bg = ctpp.base,
        }

        local right_widgets = {
            layout = wibox.layout.fixed.horizontal,
            spacing = 6,
            sysinfo_widget,
            make_separator(),
        }

        if compact then
            right_widgets.spacing = 4
        end

        if s == screen.primary then
            table.insert(right_widgets, {
                primary_systray_widget,
                left = compact and 1 or 2,
                right = compact and 1 or 2,
                widget = wibox.container.margin,
            })
            table.insert(right_widgets, make_separator())
        end

        table.insert(right_widgets, {
            mytextclock,
            left = compact and 1 or 2,
            right = compact and 4 or 6,
            widget = wibox.container.margin,
        })

        s.mywibox:setup {
            layout = wibox.layout.align.horizontal,
            {
                layout = wibox.layout.fixed.horizontal,
                spacing = 4,
                {
                    s.mytaglist,
                    left = 8,
                    right = 4,
                    widget = wibox.container.margin,
                },
                s.mylayoutbox,
                lock_button,
                make_separator(),
                s.mypromptbox,
            },
            s.mytasklist,
            right_widgets,
        }
    end)

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

return M
