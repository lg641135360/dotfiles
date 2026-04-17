local M = {}

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

    menubar.utils.terminal = terminal

    return mymainmenu
end

return M
