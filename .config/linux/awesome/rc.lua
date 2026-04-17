local build_main_menu = require("menu").build

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
require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Float window control (requires: git clone https://github.com/Elv13/collision ~/.config/awesome/collision)
pcall(function() require("collision")() end)

-- Platform detection and config
local config, platform = require("config")
local function expand_home(path)
    return (path:gsub("^~", os.getenv("HOME") or "~"))
end

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
beautiful.init(expand_home(config.theme_path))

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

local mymainmenu = build_main_menu({
    terminal = terminal,
    editor_cmd = editor_cmd,
    config = config,
    beautiful = beautiful,
    awful = awful,
    menubar = menubar,
})

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

require("ui.wibar").setup({
    modkey = modkey,
    ctpp = ctpp,
    sysinfo_widget = sysinfo_widget,
    make_separator = make_separator,
    lock_button = lock_button,
    mytextclock = mytextclock,
    systray_widget = systray_widget,
})

-- autostart (only on initial startup, not on restart)
awful.spawn.once("sh -c '~/.config/awesome/autostart.sh'")

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

local bindings = require("bindings").setup({
    modkey = modkey,
    terminal = terminal,
    mymainmenu = mymainmenu,
})

require("client").setup({
    clientkeys = bindings.clientkeys,
    clientbuttons = bindings.clientbuttons,
})

