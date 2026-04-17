local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

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
                if c.minimized then
                    text.markup = '<span color="' .. ctpp.overlay2 .. '">[min] ' .. c.name .. '</span>'
                elseif c == client.focus then
                    text.markup = '<span foreground="' .. ctpp.blue .. '"><b>' .. c.name .. '</b></span>'
                else
                    text.markup = '<span foreground="' .. ctpp.text .. '">' .. c.name .. '</span>'
                end
            end,
            update_callback = function(self, c)
                local text = self:get_children_by_id("text_role")[1]
                if c.minimized then
                    text.markup = '<span color="' .. ctpp.overlay2 .. '">[min] ' .. c.name .. '</span>'
                elseif c == client.focus then
                    text.markup = '<span foreground="' .. ctpp.blue .. '"><b>' .. c.name .. '</b></span>'
                else
                    text.markup = '<span foreground="' .. ctpp.text .. '">' .. c.name .. '</span>'
                end
            end,
        },
    }
end

function M.setup(args)
    local modkey = args.modkey
    local ctpp = args.ctpp
    local sysinfo_widget = args.sysinfo_widget
    local make_separator = args.make_separator
    local lock_button = args.lock_button
    local mytextclock = args.mytextclock
    local systray_widget = args.systray_widget

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

    local function set_wallpaper(screen)
        if beautiful.wallpaper then
            local wallpaper = beautiful.wallpaper
            if type(wallpaper) == "function" then
                wallpaper = wallpaper(screen)
            end
            gears.wallpaper.maximized(wallpaper, screen, true)
        end
    end

    screen.connect_signal("property::geometry", set_wallpaper)

    awful.screen.connect_for_each_screen(function(s)
        set_wallpaper(s)

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
            spacing = 8,
            sysinfo_widget,
            make_separator(),
        }

        if s == screen.primary then
            table.insert(right_widgets, {
                systray_widget,
                left = 4,
                right = 4,
                widget = wibox.container.margin,
            })
            table.insert(right_widgets, make_separator())
        end

        table.insert(right_widgets, {
            mytextclock,
            left = 4,
            right = 8,
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
end

return M
