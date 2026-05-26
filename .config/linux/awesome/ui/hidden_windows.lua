local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local xml_escape = gears.string.xml_escape

local excluded_types = {
    desktop = true,
    dock = true,
    splash = true,
}

local function client_label(c)
    local label = c and (c.name or c.class or c.instance) or nil
    if not label or label == "" then
        return "untitled"
    end
    return label
end

local function client_app(c)
    return c and (c.class or c.instance) or nil
end

local function client_tags(c)
    if not c then
        return {}
    end

    local ok, tags = pcall(function()
        if c.tags then
            return c:tags()
        end
        return nil
    end)
    if ok and tags then
        return tags
    end

    if c.first_tag then
        return { c.first_tag }
    end

    return {}
end

local function client_tag_label(c)
    local tags = client_tags(c)
    for _, tag in ipairs(tags) do
        if tag and tag.name and tag.name ~= "" then
            return tag.name
        end
    end
    return nil
end

local function client_matches_screen(c, target_screen)
    if not target_screen then
        return true
    end

    if c and c.screen == target_screen then
        return true
    end

    for _, tag in ipairs(client_tags(c)) do
        if tag and tag.screen == target_screen then
            return true
        end
    end

    return false
end

local function hidden_client_filter(c, target_screen)
    if not c or c.valid == false then
        return false
    end

    if c.skip_taskbar or excluded_types[c.type] then
        return false
    end

    if not (c.minimized or c.hidden) then
        return false
    end

    return client_matches_screen(c, target_screen)
end

local function collect_hidden_clients(target_screen)
    local clients = {}
    if not client or not client.get then
        return clients
    end

    for _, c in ipairs(client.get()) do
        if hidden_client_filter(c, target_screen) then
            clients[#clients + 1] = c
        end
    end

    table.sort(clients, function(a, b)
        if (a.urgent == true) ~= (b.urgent == true) then
            return a.urgent == true
        end
        return client_label(a) < client_label(b)
    end)

    return clients
end

local active_menu

local function hidden_clients_signature(clients)
    local parts = {}
    for index, c in ipairs(clients or {}) do
        parts[index] = table.concat({
            tostring(c),
            c.hidden and "hidden" or "visible",
            c.minimized and "minimized" or "normal",
            c.urgent and "urgent" or "normal",
        }, ":")
    end
    return table.concat(parts, "|")
end

local function hide_active_menu()
    if not active_menu then
        return
    end

    if active_menu.hide then
        pcall(function()
            active_menu:hide()
        end)
    end
    active_menu = nil
end

local function hidden_tooltip_text(clients)
    if #clients == 0 then
        return "隐藏窗口\n无"
    end

    local hidden_count = 0
    local minimized_count = 0
    local urgent_count = 0
    for _, c in ipairs(clients) do
        if c.urgent then
            urgent_count = urgent_count + 1
        end
        if c.hidden then
            hidden_count = hidden_count + 1
        elseif c.minimized then
            minimized_count = minimized_count + 1
        end
    end

    local lines = {
        "隐藏窗口",
        "数量：" .. #clients .. "（紧急 " .. urgent_count .. " / 隐藏 " .. hidden_count .. " / 最小化 " .. minimized_count .. "）",
    }
    for index, c in ipairs(clients) do
        local line = index .. ". " .. client_label(c)
        local app = client_app(c)
        local tag_name = client_tag_label(c)
        local details = {}

        if app and app ~= "" then
            details[#details + 1] = app
        end
        if tag_name and tag_name ~= "" then
            details[#details + 1] = "标签 " .. tag_name
        end
        if c.urgent then
            details[#details + 1] = "紧急"
        end
        if c.hidden then
            details[#details + 1] = "隐藏"
        elseif c.minimized then
            details[#details + 1] = "最小化"
        end

        if #details > 0 then
            line = line .. "（" .. table.concat(details, " / ") .. "）"
        end
        lines[#lines + 1] = line
    end

    lines[#lines + 1] = "左键：恢复第一个"
    lines[#lines + 1] = "右键：选择恢复"
    return table.concat(lines, "\n")
end

local function restore_client(c)
    hide_active_menu()

    if not c or c.valid == false then
        return
    end

    c.hidden = false
    c.minimized = false

    if c.jump_to then
        c:jump_to(false)
        return
    end

    local tag = c.first_tag or client_tags(c)[1]
    if tag and tag.view_only then
        tag:view_only()
    end

    if client then
        client.focus = c
    end
    if c.raise then
        c:raise()
    end
    if c.emit_signal then
        c:emit_signal("request::activate", "hidden_indicator", { raise = true })
    end
end

local function restore_first_hidden(target_screen)
    local clients = collect_hidden_clients(target_screen)
    restore_client(clients[1])
end

local function show_hidden_menu(target_screen)
    local clients = collect_hidden_clients(target_screen)
    local items = {}

    hide_active_menu()

    if #clients == 0 then
        return
    end

    for _, c in ipairs(clients) do
        local label = client_label(c)
        local tag_name = client_tag_label(c)
        if tag_name then
            label = label .. "  ·  " .. tag_name
        end
        items[#items + 1] = {
            label,
            function()
                restore_client(c)
            end,
        }
    end

    active_menu = awful.menu({
        items = items,
        theme = { width = 320 },
        _hidden_signature = hidden_clients_signature(clients),
    })
    active_menu:show()
end

local function connect_refresh_signals(target_screen, queue_update)
    if client and client.connect_signal then
        for _, signal in ipairs({
            "property::minimized",
            "property::hidden",
            "property::urgent",
            "property::name",
            "property::class",
            "property::skip_taskbar",
            "property::screen",
            "tagged",
            "untagged",
            "manage",
            "unmanage",
            "focus",
            "unfocus",
            "list",
        }) do
            client.connect_signal(signal, queue_update)
        end
    end

    if awful.tag and awful.tag.attached_connect_signal then
        awful.tag.attached_connect_signal(target_screen, "property::selected", queue_update)
        awful.tag.attached_connect_signal(target_screen, "property::activated", queue_update)
    end
end

local function create_indicator(ctpp, target_screen)
    local indicator = wibox.widget {
        {
            {
                {
                    id = "hidden_indicator_text_role",
                    widget = wibox.widget.textbox,
                },
                id = "hidden_indicator_constraint_role",
                strategy = "max",
                width = dpi(180),
                widget = wibox.container.constraint,
            },
            left = dpi(6),
            right = dpi(6),
            top = dpi(1),
            bottom = dpi(1),
            widget = wibox.container.margin,
        },
        id = "hidden_indicator_background_role",
        bg = ctpp.base,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background,
    }

    indicator:buttons(gears.table.join(
        awful.button({}, 1, function()
            restore_first_hidden(target_screen)
        end),
        awful.button({}, 3, function()
            show_hidden_menu(target_screen)
        end)
    ))

    awful.tooltip {
        objects = { indicator },
        timer_function = function()
            return indicator._tooltip_text or ""
        end,
    }

    function indicator:update(close_menu)
        if close_menu then
            hide_active_menu()
        end

        local clients = collect_hidden_clients(target_screen)
        local hidden_count = #clients
        local first = clients[1]
        local has_urgent = first and first.urgent == true
        local label
        if hidden_count == 1 then
            label = "隐:" .. client_label(first)
        else
            label = "隐:" .. client_label(first) .. " +" .. (hidden_count - 1)
        end
        local fg = has_urgent and ctpp.red or ctpp.overlay1

        local text = self:get_children_by_id("hidden_indicator_text_role")[1]
        if text then
            text.markup = "<span foreground='" .. fg .. "'><b>" .. xml_escape(label) .. "</b></span>"
        end

        local background = self:get_children_by_id("hidden_indicator_background_role")[1]
        if background then
            background.bg = has_urgent and ctpp.surface0 or ctpp.mantle
        end

        self._tooltip_text = hidden_tooltip_text(clients)
        self.visible = hidden_count > 0
    end

    local queued_update = false
    local function queue_update()
        if queued_update then
            return
        end

        queued_update = true
        gears.timer.delayed_call(function()
            queued_update = false
            indicator:update(true)
        end)
    end

    connect_refresh_signals(target_screen, queue_update)
    indicator:update()

    return indicator
end

return {
    create_indicator = create_indicator,
    _private = {
        client_label = client_label,
        client_tag_label = client_tag_label,
        hidden_client_filter = hidden_client_filter,
        collect_hidden_clients = collect_hidden_clients,
        hidden_tooltip_text = hidden_tooltip_text,
        hidden_clients_signature = hidden_clients_signature,
        hide_active_menu = hide_active_menu,
        restore_client = restore_client,
    },
}
