local awful = require("awful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")

local M = {}

local function view_previous_occupied_tag()
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
end

local function view_next_occupied_tag()
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
end

function M.setup(args)
    local modkey = args.modkey
    local terminal = args.terminal
    local mymainmenu = args.mymainmenu

    local globalkeys = gears.table.join(
        awful.key({ modkey }, "s", function()
            awful.spawn.with_shell("maim -s ~/.cache/com.pot-app.desktop/pot_screenshot_cut.png && curl '127.0.0.1:60828/ocr_translate?screenshot=false'")
        end, { description = "screenshot and ocr", group = "launcher" }),
        awful.key({ modkey, "Shift" }, "s", hotkeys_popup.show_help,
            { description = "show help", group = "awesome" }),
        awful.key({ modkey }, "Escape", awful.tag.history.restore,
            { description = "go back", group = "tag" }),

        awful.key({ modkey }, "j", function()
            awful.client.focus.byidx(1)
        end, { description = "focus next by index", group = "client" }),
        awful.key({ modkey }, "k", function()
            awful.client.focus.byidx(-1)
        end, { description = "focus previous by index", group = "client" }),
        awful.key({ modkey }, "w", function()
            mymainmenu:show()
        end, { description = "show main menu", group = "awesome" }),

        awful.key({ modkey, "Shift" }, "j", function()
            awful.client.swap.byidx(1)
        end, { description = "swap with next client by index", group = "client" }),
        awful.key({ modkey, "Shift" }, "k", function()
            awful.client.swap.byidx(-1)
        end, { description = "swap with previous client by index", group = "client" }),
        awful.key({ modkey }, "]", function()
            awful.screen.focus_relative(1)
        end, { description = "focus the next screen", group = "screen" }),
        awful.key({ modkey }, "[", function()
            awful.screen.focus_relative(-1)
        end, { description = "focus the previous screen", group = "screen" }),
        awful.key({ modkey }, "u", awful.client.urgent.jumpto,
            { description = "jump to urgent client", group = "client" }),
        awful.key({ modkey }, "Tab", function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end, { description = "go back", group = "client" }),

        awful.key({ modkey }, "a", view_previous_occupied_tag,
            { description = "view previous tag with clients", group = "tag" }),
        awful.key({ modkey }, "d", view_next_occupied_tag,
            { description = "view next tag with clients", group = "tag" }),

        awful.key({ modkey }, "Return", function()
            awful.spawn(terminal)
        end, { description = "open a terminal", group = "launcher" }),
        awful.key({ modkey }, "e", function()
            awful.spawn("dolphin")
        end, { description = "open a file manager[dolphin]", group = "launcher" }),
        awful.key({ modkey, "Control" }, "r", awesome.restart,
            { description = "reload awesome", group = "awesome" }),
        awful.key({ modkey, "Shift" }, "q", awesome.quit,
            { description = "quit awesome", group = "awesome" }),

        awful.key({ modkey }, "l", function()
            awful.tag.incmwfact(0.05)
        end, { description = "increase master width factor", group = "layout" }),
        awful.key({ modkey }, "h", function()
            awful.tag.incmwfact(-0.05)
        end, { description = "decrease master width factor", group = "layout" }),
        awful.key({ modkey, "Shift" }, "h", function()
            awful.tag.incnmaster(1, nil, true)
        end, { description = "increase the number of master clients", group = "layout" }),
        awful.key({ modkey, "Shift" }, "l", function()
            awful.tag.incnmaster(-1, nil, true)
        end, { description = "decrease the number of master clients", group = "layout" }),
        awful.key({ modkey, "Control" }, "h", function()
            awful.tag.incncol(1, nil, true)
        end, { description = "increase the number of columns", group = "layout" }),
        awful.key({ modkey, "Control" }, "l", function()
            awful.tag.incncol(-1, nil, true)
        end, { description = "decrease the number of columns", group = "layout" }),
        awful.key({ modkey }, "space", function()
            awful.layout.inc(1)
        end, { description = "select next", group = "layout" }),
        awful.key({ modkey, "Shift" }, "space", function()
            awful.layout.inc(-1)
        end, { description = "select previous", group = "layout" }),

        awful.key({ modkey, "Control" }, "n", function()
            local c = awful.client.restore()
            if c then
                c:emit_signal("request::activate", "key.unminimize", { raise = true })
            end
        end, { description = "restore minimized", group = "client" }),

        awful.key({ modkey }, "r", function()
            awful.screen.focused().mypromptbox:run()
        end, { description = "run prompt", group = "launcher" }),
        awful.key({ modkey }, "x", function()
            awful.prompt.run {
                prompt = "Run Lua code: ",
                textbox = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval",
            }
        end, { description = "lua execute prompt", group = "awesome" }),
        awful.key({ modkey }, "c", function()
            awful.spawn.with_shell(
                "LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LC_CTYPE=zh_CN.UTF-8 GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx rofi -show drun"
            )
        end, { description = "show rofi drun launcher", group = "launcher" }),
        awful.key({ modkey, "Control" }, "l", function()
            awful.spawn.with_shell("~/.config/scripts/lock")
        end, { description = "lock screen", group = "custom" })
    )

    local clientkeys = gears.table.join(
        awful.key({ modkey }, "f", function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end, { description = "toggle fullscreen", group = "client" }),
        awful.key({ modkey }, "q", function(c)
            c:kill()
        end, { description = "close", group = "client" }),
        awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,
            { description = "toggle floating", group = "client" }),
        awful.key({ modkey, "Control" }, "Return", function(c)
            c:swap(awful.client.getmaster())
        end, { description = "move to master", group = "client" }),
        awful.key({ modkey }, "o", function(c)
            c:move_to_screen()
        end, { description = "move to screen", group = "client" }),
        awful.key({ modkey }, "t", function(c)
            c.ontop = not c.ontop
        end, { description = "toggle keep on top", group = "client" }),
        awful.key({ modkey }, "n", function(c)
            c.minimized = true
        end, { description = "minimize", group = "client" }),
        awful.key({ modkey }, "m", function(c)
            c.maximized = not c.maximized
            c:raise()
        end, { description = "(un)maximize", group = "client" }),
        awful.key({ modkey, "Control" }, "m", function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end, { description = "(un)maximize vertically", group = "client" }),
        awful.key({ modkey, "Shift" }, "m", function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end, { description = "(un)maximize horizontally", group = "client" })
    )

    for i = 1, 9 do
        globalkeys = gears.table.join(globalkeys,
            awful.key({ modkey }, "#" .. i + 9, function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end, { description = "view tag #" .. i, group = "tag" }),
            awful.key({ modkey, "Control" }, "#" .. i + 9, function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end, { description = "toggle tag #" .. i, group = "tag" }),
            awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end, { description = "move focused client to tag #" .. i, group = "tag" }),
            awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end, { description = "toggle focused client on tag #" .. i, group = "tag" })
        )
    end

    local clientbuttons = gears.table.join(
        awful.button({}, 1, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
        end),
        awful.button({ modkey }, 1, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({ modkey }, 3, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    root.keys(globalkeys)

    return {
        globalkeys = globalkeys,
        clientkeys = clientkeys,
        clientbuttons = clientbuttons,
    }
end

return M
