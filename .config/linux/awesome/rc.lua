-- Unified AwesomeWM configuration
-- Auto-detects platform and applies appropriate settings

pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Float window control (requires: git clone https://github.com/Elv13/collision ~/.config/awesome/collision)
pcall(function() require("collision")() end)

-- Platform detection and config
local config, platform = require("config")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Theme
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme/catppuccin.lua")

-- Get Catppuccin palette from beautiful
local ctpp = beautiful.ctpp

-- This is used later as the default terminal and editor to run.
local terminal = "alacritty"
local editor = config.editor
local editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    -- awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.floating,
    awful.layout.suit.max
}
-- }}}

-- {{{ Menu
local myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

local mymainmenu
if config.menu_style == "freedesktop" then
    local has_fdo, freedesktop = pcall(require, "freedesktop")
    if has_fdo then
        mymainmenu = freedesktop.menu.build({
            before = { menu_awesome },
            after =  { menu_terminal }
        })
    else
        mymainmenu = awful.menu({
            items = {
                      menu_awesome,
                      { "Debian", require("debian.menu").Debian_menu.Debian },
                      menu_terminal,
                    }
        })
    end
else
    mymainmenu = awful.menu({ items = { menu_awesome, menu_terminal } })
end

local mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Widgets
local lain_ok, lain = pcall(require, "lain")
if not lain_ok then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "AwesomeWM: missing dependency",
        text = "Please install lain: git clone https://github.com/lcpz/lain.git ~/.config/awesome/lain",
    })
end
local dpi = require("beautiful.xresources").apply_dpi

-- System info widgets (CPU, MEM, NET) — requires lain
local sysinfo_widget
local make_separator
if lain_ok then
    local system_widgets = require("widgets.system").create(config)
    sysinfo_widget = system_widgets.sysinfo_widget
    make_separator = system_widgets.make_separator

    -- Volume widget (optional, platform-dependent)
    local vol_widget
    local has_volume = config.has_volume
    if has_volume then
        vol_widget = require("widgets.volume").create()
        sysinfo_widget:insert(sysinfo_widget:count() - 1, make_separator())
        sysinfo_widget:insert(sysinfo_widget:count() - 1, vol_widget)
    end
else
    -- Fallback: empty placeholder
    sysinfo_widget = wibox.widget {
        markup = "<span foreground='#666'>[lain missing]</span>",
        widget = wibox.widget.textbox,
    }
    make_separator = function()
        return wibox.widget { markup = " ", widget = wibox.widget.textbox }
    end
end

-- Lock screen button widget with background
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
    awful.button({ }, 1, function()
        awful.spawn.with_shell("~/.config/scripts/lock")
    end)
))

-- Create a textclock widget
local mytextclock = wibox.widget.textbox()
gears.timer {
    timeout = 60,
    autostart = true,
    call_now = true,
    callback = function()
        local time_str = os.date(config.date_format)
        mytextclock:set_markup("<span foreground='" .. ctpp.lavender .. "'>" .. time_str .. "</span>")
    end
}

-- Create systray widget with styling
local systray = wibox.widget.systray()
systray:set_base_size(dpi(22))

local systray_widget = wibox.widget {
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
-- }}}

-- {{{ Wibar
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "󰇩 ", "󰓠 ", "󰠮 ", " ", " " }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create a text-based layout indicator with style
    local mylayoutbox_widget = wibox.widget {
        markup = " [M] ",
        widget = wibox.widget.textbox,
    }
    s.mylayoutbox = wibox.widget {
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
        local layout_name = awful.layout.getname(awful.layout.get(s))
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
            cornerse = "└─┘"
        }
        mylayoutbox_widget.markup = " <span foreground='" .. ctpp.mauve .. "'> " .. (layout_text[layout_name] or layout_name) .. " </span>"
    end
    update_layoutbox()
    awful.tag.attached_connect_signal(s, "property::selected", update_layoutbox)
    awful.tag.attached_connect_signal(s, "property::layout", update_layoutbox)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) update_layoutbox() end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) update_layoutbox() end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) update_layoutbox() end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) update_layoutbox() end)))

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget (show all windows in current tag)
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        widget_template = {
            {
                {
                    {
                        id     = 'icon_role',
                        widget = wibox.widget.imagebox,
                    },
                    valign = "center",
                    widget  = wibox.container.place,
                },
                {
                    id     = 'text_role',
                    widget = wibox.widget.textbox,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            left  = 8,
            right = 8,
            widget = wibox.container.margin,
            create_callback = function(self, c, index, objects)
                local img = self:get_children_by_id('icon_role')[1]
                if img then
                    img.forced_width = dpi(20)
                    img.forced_height = dpi(20)
                end
                local text = self:get_children_by_id('text_role')[1]
                if c.minimized then
                    text.markup = '<span color="' .. ctpp.overlay2 .. '">[min] ' .. c.name .. '</span>'
                elseif c == client.focus then
                    text.markup = '<span foreground="' .. ctpp.blue .. '"><b>' .. c.name .. '</b></span>'
                else
                    text.markup = '<span foreground="' .. ctpp.text .. '">' .. c.name .. '</span>'
                end
            end,
            update_callback = function(self, c, index, objects)
                local text = self:get_children_by_id('text_role')[1]
                if c.minimized then
                    text.markup = '<span color="' .. ctpp.overlay2 .. '">[min] ' .. c.name .. '</span>'
                elseif c == client.focus then
                    text.markup = '<span foreground="' .. ctpp.blue .. '"><b>' .. c.name .. '</b></span>'
                else
                    text.markup = '<span foreground="' .. ctpp.text .. '">' .. c.name .. '</span>'
                end
            end
        },
    }

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        bg = ctpp.base,
    })

    -- Add widgets to the wibox with better spacing
    local right_widgets = {
        layout = wibox.layout.fixed.horizontal,
        spacing = 8,
        sysinfo_widget,
        make_separator(),
    }

    -- Only add systray on primary screen
    if s == screen.primary then
        table.insert(right_widgets, {
            systray_widget,
            left = 4,
            right = 4,
            widget = wibox.container.margin,
        })
        table.insert(right_widgets, make_separator())
    end

    -- Add clock (all screens)
    table.insert(right_widgets, {
        mytextclock,
        left = 4,
        right = 8,
        widget = wibox.container.margin,
    })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
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
        s.mytasklist, -- Tasklist in the middle
        right_widgets, -- Right widgets
    }
end)
-- }}}

-- autostart (only on initial startup, not on restart)
awful.spawn.once("sh -c '~/.config/awesome/autostart.sh'")

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      function() awful.spawn.with_shell("maim -s ~/.cache/com.pot-app.desktop/pot_screenshot_cut.png && curl '127.0.0.1:60828/ocr_translate?screenshot=false'") end,
              {description="screenshot and ocr", group="launcher"}),
    awful.key({ modkey, "Shift" }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, }, "]", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, }, "[", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Custom keybindings for switching between occupied tags
    awful.key({ modkey,           }, "a", function ()
            local screen = awful.screen.focused()
            local tags = screen.tags
            local target_tag = nil
            local current_tag_index = 0

            for i, tag in ipairs(tags) do
                if tag.selected then
                    current_tag_index = i
                    break
                end
            end

            for i = current_tag_index - 1, 1, -1 do
                if #tags[i]:clients() > 0 then
                    target_tag = tags[i]
                    break
                end
            end

            if not target_tag then
                for i = #tags, current_tag_index + 1, -1 do
                    if #tags[i]:clients() > 0 then
                        target_tag = tags[i]
                        break
                    end
                end
            end

            if target_tag then
                target_tag:view_only()
            end
        end,
        {description = "view previous tag with clients", group = "tag"}),
    awful.key({ modkey,           }, "d", function ()
            local screen = awful.screen.focused()
            local tags = screen.tags
            local target_tag = nil
            local current_tag_index = 0

            for i, tag in ipairs(tags) do
                if tag.selected then
                    current_tag_index = i
                    break
                end
            end

            for i = current_tag_index + 1, #tags do
                if #tags[i]:clients() > 0 then
                    target_tag = tags[i]
                    break
                end
            end

            if not target_tag then
                for i = 1, current_tag_index - 1 do
                    if #tags[i]:clients() > 0 then
                        target_tag = tags[i]
                        break
                    end
                end
            end

            if target_tag then
                target_tag:view_only()
            end
        end,
        {description = "view next tag with clients", group = "tag"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey,           }, "e", function () awful.spawn("dolphin") end,
              {description = "open a file manager[dolphin]", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "c", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),
    -- lock screen
    awful.key({ modkey, "Control" }, "l", function() awful.spawn.with_shell("~/.config/scripts/lock") end, {description = "lock screen", group = "custom"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, }, "q",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",
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
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },
}
-- }}}

-- {{{ Signals
client.connect_signal("manage", function (c)
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
