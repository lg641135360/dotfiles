local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

local function apply_client_shape(c)
    if c.fullscreen or c.maximized or c.maximized_horizontal or c.maximized_vertical then
        c.shape = gears.shape.rectangle
        return
    end

    c.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, beautiful.border_radius or 0)
    end
end

local function update_titlebar_style(c)
    local titlebar = c._fallback_titlebar
    local background = c._fallback_titlebar_background
    if not titlebar or not background then
        return
    end

    local focused = c == client.focus
    local bg = focused and (beautiful.titlebar_bg_focus or beautiful.bg_focus) or (beautiful.titlebar_bg_normal or beautiful.bg_normal)
    local fg = focused and (beautiful.titlebar_fg_focus or beautiful.fg_focus) or (beautiful.titlebar_fg_normal or beautiful.fg_normal)

    titlebar.bg = bg
    titlebar.fg = fg
    background.bg = bg
    background.border_color = focused and (beautiful.titlebar_border_color_focus or beautiful.titlebar_border_color or beautiful.border_focus)
        or (beautiful.titlebar_border_color or beautiful.border_normal)

    for _, refresh in ipairs(c._fallback_titlebar_refreshers or {}) do
        refresh()
    end
end

local function titlebar_button_markup(label, color)
    return "<span foreground='" .. color .. "'><b>" .. label .. "</b></span>"
end

local function titlebar_button_colors(kind, active)
    if active then
        return beautiful.titlebar_button_bg_active or beautiful.titlebar_bg_focus or beautiful.bg_focus,
            beautiful.titlebar_button_fg_active or beautiful.titlebar_fg_focus or beautiful.fg_focus
    end

    if kind == "close" then
        return beautiful.titlebar_button_bg_close or beautiful.titlebar_button_bg_normal or beautiful.titlebar_bg_normal or beautiful.bg_normal,
            beautiful.titlebar_button_fg_close or beautiful.titlebar_fg_focus or beautiful.fg_focus
    end

    return beautiful.titlebar_button_bg_normal or beautiful.titlebar_bg_normal or beautiful.bg_normal,
        beautiful.titlebar_button_fg_normal or beautiful.titlebar_fg_normal or beautiful.fg_normal
end

local function create_titlebar_control(c, spec)
    local text = wibox.widget {
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    }
    text.font = beautiful.titlebar_button_font or beautiful.titlebar_font or beautiful.font

    local button = wibox.widget {
        {
            text,
            left = beautiful.titlebar_button_padding_x or dpi(5),
            right = beautiful.titlebar_button_padding_x or dpi(5),
            top = beautiful.titlebar_button_padding_y or dpi(1),
            bottom = beautiful.titlebar_button_padding_y or dpi(1),
            widget = wibox.container.margin,
        },
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, beautiful.titlebar_button_radius or beautiful.titlebar_radius or beautiful.border_radius or 0)
        end,
        widget = wibox.container.background,
    }

    local function update()
        local active = spec.is_active and spec.is_active(c) or false
        local bg, fg = titlebar_button_colors(spec.kind, active)
        local label = spec.label
        if spec.active_label and active then
            label = spec.active_label
        end

        button.bg = bg
        text.markup = titlebar_button_markup(label, fg)
    end

    button:buttons(gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            spec.on_click(c)
            gears.timer.delayed_call(function()
                update_titlebar_style(c)
            end)
        end)
    ))

    return button, update
end

function M.setup(args)
    local clientkeys = args.clientkeys
    local clientbuttons = args.clientbuttons

    awful.rules.rules = {
        {
            rule = {},
            properties = {
                border_width = beautiful.border_width,
                border_color = beautiful.border_normal,
                focus = awful.client.focus.filter,
                raise = true,
                keys = clientkeys,
                buttons = clientbuttons,
                screen = awful.screen.preferred,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen,
                size_hints_honor = false,
                titlebars_enabled = false,
            },
        },
        {
            rule_any = {
                instance = {
                    "copyq",
                    "pinentry",
                },
                class = {
                    "Arandr",
                    "Blueman-manager",
                    "Gpick",
                    "Kruler",
                    "MessageWin",
                    "Sxiv",
                    "Tor Browser",
                    "Wpa_gui",
                    "veromix",
                    "xtightvncviewer",
                    "Pot",
                },
                name = {
                    "Event Tester",
                },
                role = {
                    "AlarmWindow",
                    "ConfigManager",
                    "pop-up",
                },
            },
            properties = { floating = true },
        },
        {
            rule_any = {
                class = {
                    "Arandr",
                    "Blueman-manager",
                    "Gpick",
                    "Kruler",
                    "MessageWin",
                    "Pot",
                    "Wpa_gui",
                    "veromix",
                    "xtightvncviewer",
                },
            },
            except_any = {
                class = {
                    "tblive",
                },
            },
            properties = { titlebars_enabled = true },
        },
        {
            rule = { class = "tblive", type = "utility" },
            properties = {
                floating = true,
                skip_taskbar = true,
            },
        },
    }

    client.connect_signal("manage", function(c)
        if awesome.startup
            and not c.size_hints.user_position
            and not c.size_hints.program_position then
            awful.placement.no_offscreen(c)
        end

        apply_client_shape(c)
    end)

    client.connect_signal("property::fullscreen", apply_client_shape)
    client.connect_signal("property::maximized", apply_client_shape)
    client.connect_signal("property::maximized_horizontal", apply_client_shape)
    client.connect_signal("property::maximized_vertical", apply_client_shape)

    client.connect_signal("request::titlebars", function(c)
        local buttons = gears.table.join(
            awful.button({}, 1, function()
                c:emit_signal("request::activate", "titlebar", { raise = true })
                awful.mouse.client.move(c)
            end),
            awful.button({}, 3, function()
                c:emit_signal("request::activate", "titlebar", { raise = true })
                awful.mouse.client.resize(c)
            end)
        )

        local titlebar = awful.titlebar(c, {
            size = beautiful.titlebar_size or dpi(26),
        })
        local title_widget = awful.titlebar.widget.titlewidget(c)
        local control_spacing = beautiful.titlebar_spacing or dpi(3)
        local side_padding = beautiful.titlebar_side_padding or dpi(6)
        local section_padding = beautiful.titlebar_section_padding or dpi(4)
        local floating_button, update_floating_button = create_titlebar_control(c, {
            kind = "toggle",
            label = "◇",
            active_label = "◆",
            is_active = function(client_object)
                return client_object.floating
            end,
            on_click = function(client_object)
                awful.client.floating.toggle(client_object)
            end,
        })
        local maximize_button, update_maximize_button = create_titlebar_control(c, {
            kind = "toggle",
            label = "□",
            active_label = "▣",
            is_active = function(client_object)
                return client_object.maximized or client_object.maximized_horizontal or client_object.maximized_vertical
            end,
            on_click = function(client_object)
                client_object.maximized = not client_object.maximized
                client_object:raise()
            end,
        })
        local close_button, update_close_button = create_titlebar_control(c, {
            kind = "close",
            label = "×",
            on_click = function(client_object)
                client_object:kill()
            end,
        })

        title_widget.font = beautiful.titlebar_font or beautiful.font
        local background = wibox.widget {
            {
                {
                    {
                        align = "left",
                        valign = "center",
                        widget = title_widget,
                    },
                    buttons = buttons,
                    left = side_padding,
                    right = section_padding,
                    widget = wibox.container.margin,
                },
                {
                    {
                        floating_button,
                        maximize_button,
                        close_button,
                        spacing = control_spacing,
                        layout = wibox.layout.fixed.horizontal(),
                    },
                    right = side_padding,
                    widget = wibox.container.margin,
                },
                layout = wibox.layout.align.horizontal,
            },
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, beautiful.titlebar_radius or beautiful.border_radius or 0)
            end,
            border_width = beautiful.titlebar_border_width or dpi(1),
            border_color = beautiful.titlebar_border_color or beautiful.border_normal,
            widget = wibox.container.background,
        }

        titlebar:setup {
            {
                background,
                left = dpi(3),
                right = dpi(3),
                top = dpi(2),
                bottom = 0,
                widget = wibox.container.margin,
            },
            layout = wibox.layout.flex.horizontal,
        }

        c._fallback_titlebar = titlebar
        c._fallback_titlebar_background = background
        c._fallback_titlebar_refreshers = {
            update_floating_button,
            update_maximize_button,
            update_close_button,
        }
        update_titlebar_style(c)
    end)

    client.connect_signal("focus", function(c)
        c.border_color = beautiful.border_focus
        update_titlebar_style(c)
    end)
    client.connect_signal("unfocus", function(c)
        c.border_color = beautiful.border_normal
        update_titlebar_style(c)
    end)
    client.connect_signal("property::floating", update_titlebar_style)
    client.connect_signal("property::maximized", update_titlebar_style)
    client.connect_signal("property::maximized_horizontal", update_titlebar_style)
    client.connect_signal("property::maximized_vertical", update_titlebar_style)
end

return M
