local M = {}

local function build_basic_menu(awful, menu_awesome, menu_terminal)
    return awful.menu({ items = { menu_awesome, menu_terminal } })
end

local function build_debian_menu(awful, menu_awesome, menu_terminal)
    local has_debian, debian_menu = pcall(require, "debian.menu")
    if has_debian and debian_menu and debian_menu.Debian_menu and debian_menu.Debian_menu.Debian then
        return awful.menu({
            items = {
                menu_awesome,
                { "Debian", debian_menu.Debian_menu.Debian },
                menu_terminal,
            }
        })
    end

    return build_basic_menu(awful, menu_awesome, menu_terminal)
end

local function build_auto_menu(awful, menu_awesome, menu_terminal)
    local has_fdo, freedesktop = pcall(require, "freedesktop")
    if has_fdo and freedesktop and freedesktop.menu and freedesktop.menu.build then
        return freedesktop.menu.build({
            before = { menu_awesome },
            after = { menu_terminal },
        })
    end

    return build_debian_menu(awful, menu_awesome, menu_terminal)
end

function M.build(args)
    local terminal = args.terminal
    local editor_cmd = args.editor_cmd
    local config = args.config
    local beautiful = args.beautiful
    local awful = args.awful
    local menubar = args.menubar
    local hotkeys_popup = require("awful.hotkeys_popup")

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
    if config.menu_style == "basic" then
        mymainmenu = build_basic_menu(awful, menu_awesome, menu_terminal)
    else
        mymainmenu = build_auto_menu(awful, menu_awesome, menu_terminal)
    end

    menubar.utils.terminal = terminal

    return mymainmenu
end

return M
