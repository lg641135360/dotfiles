local awful = require("awful")
local gears = require("gears")

local M = {}

local excluded_types = {
    desktop = true,
    dock = true,
    splash = true,
}

local active_menu

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

local function selected_tags(target_screen)
    local tags = {}
    local selected = target_screen and target_screen.selected_tags or nil

    for _, tag in ipairs(selected or {}) do
        if tag then
            tags[#tags + 1] = tag
        end
    end

    if #tags == 0 and target_screen and target_screen.selected_tag then
        tags[#tags + 1] = target_screen.selected_tag
    end

    return tags
end

local function tag_name(tag)
    if tag and tag.name and tag.name ~= "" then
        return tag.name
    end
    return nil
end

local function client_tag_label(c, target_screen)
    local selected = selected_tags(target_screen)
    local selected_set = {}

    for _, tag in ipairs(selected) do
        selected_set[tag] = true
    end

    for _, tag in ipairs(client_tags(c)) do
        if selected_set[tag] then
            return tag_name(tag)
        end
    end

    for _, tag in ipairs(client_tags(c)) do
        local name = tag_name(tag)
        if name then
            return name
        end
    end

    return nil
end

local function is_regular_client(c)
    return c
        and c.valid ~= false
        and not c.skip_taskbar
        and not excluded_types[c.type]
end

local function client_on_selected_tag(c, target_screen)
    local selected = selected_tags(target_screen)
    if #selected == 0 then
        return false
    end

    local selected_set = {}
    for _, tag in ipairs(selected) do
        selected_set[tag] = true
    end

    for _, tag in ipairs(client_tags(c)) do
        if selected_set[tag] then
            return true
        end
    end

    return false
end

local function collect_current_tag_clients(target_screen)
    local clients = {}
    if not client or not client.get then
        return clients
    end

    for _, c in ipairs(client.get()) do
        if is_regular_client(c) and client_on_selected_tag(c, target_screen) then
            clients[#clients + 1] = c
        end
    end

    table.sort(clients, function(a, b)
        if (a.urgent == true) ~= (b.urgent == true) then
            return a.urgent == true
        end
        if client and ((a == client.focus) ~= (b == client.focus)) then
            return a == client.focus
        end

        local a_hidden = a.hidden or a.minimized
        local b_hidden = b.hidden or b.minimized
        if a_hidden ~= b_hidden then
            return not a_hidden
        end

        return client_label(a) < client_label(b)
    end)

    return clients
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

local function state_parts(c)
    local parts = {}
    if c.urgent then
        parts[#parts + 1] = "urgent"
    end
    if c.hidden then
        parts[#parts + 1] = "hidden"
    elseif c.minimized then
        parts[#parts + 1] = "minimized"
    end
    return parts
end

local function menu_item_label(c, target_screen)
    local parts = { client_label(c) }
    local app = client_app(c)
    if app and app ~= "" then
        parts[#parts + 1] = app
    end

    local state = state_parts(c)
    local tag = client_tag_label(c, target_screen)
    if tag and tag ~= "" then
        state[#state + 1] = "tag " .. tag
    end

    if #state > 0 then
        parts[#parts + 1] = table.concat(state, " / ")
    end

    return table.concat(parts, "  ·  ")
end

local function restore_or_activate_client(c)
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
        c:emit_signal("request::activate", "window_menu", { raise = true })
    end
end

local function show_current_tag_menu(target_screen)
    local clients = collect_current_tag_clients(target_screen)
    local items = {}

    hide_active_menu()

    if #clients == 0 then
        return
    end

    for _, c in ipairs(clients) do
        items[#items + 1] = {
            menu_item_label(c, target_screen),
            function()
                restore_or_activate_client(c)
            end,
        }
    end

    active_menu = awful.menu({
        items = items,
        theme = { width = 360 },
    })
    active_menu:show()
end

M.show_current_tag_menu = show_current_tag_menu
M._private = {
    client_label = client_label,
    client_tag_label = client_tag_label,
    is_regular_client = is_regular_client,
    collect_current_tag_clients = collect_current_tag_clients,
    menu_item_label = menu_item_label,
    restore_or_activate_client = restore_or_activate_client,
    hide_active_menu = hide_active_menu,
}

return M
