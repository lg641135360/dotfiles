local build_main_menu = require("menu").build

-- Unified AwesomeWM configuration
-- Auto-detects platform and applies appropriate settings

pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local actions = require("actions")

-- Float window control (requires: git clone https://github.com/Elv13/collision ~/.config/awesome/collision)
pcall(function() require("collision")() end)

-- Platform detection and config
local config = require("config")
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
beautiful.init(expand_home(config.theme_path))

local ctpp = beautiful.ctpp
local terminal = "alacritty"
local editor = config.editor
local editor_cmd = terminal .. " -e " .. editor
local modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.tile.left,
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

local wibar_actions = require("ui.wibar").setup({
    modkey = modkey,
    ctpp = ctpp,
    config = config,
    actions = actions,
})

local display_layout_refresh_queued = false
local function queue_display_layout_refresh()
    if display_layout_refresh_queued then
        return
    end

    display_layout_refresh_queued = true
    gears.timer.start_new(1, function()
        display_layout_refresh_queued = false
        awful.spawn.easy_async_with_shell(
            "test -x ~/.config/awesome/display-layout.sh && ~/.config/awesome/display-layout.sh >/dev/null 2>&1",
            function() end
        )
        return false
    end)
end

-- autostart (only on initial startup, not on restart)
awful.spawn.once("sh -c '~/.config/awesome/autostart.sh'")

screen.connect_signal("added", queue_display_layout_refresh)
screen.connect_signal("removed", queue_display_layout_refresh)
awesome.connect_signal("screen::change", queue_display_layout_refresh)

root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

local bindings = require("bindings").setup({
    modkey = modkey,
    terminal = terminal,
    mymainmenu = mymainmenu,
    actions = actions,
    run_prompt = wibar_actions.run_prompt,
    run_lua_prompt = wibar_actions.run_lua_prompt,
})

require("client").setup({
    clientkeys = bindings.clientkeys,
    clientbuttons = bindings.clientbuttons,
})
