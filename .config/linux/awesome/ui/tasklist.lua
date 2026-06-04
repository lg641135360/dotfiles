local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local xml_escape = gears.string.xml_escape

local excluded_task_types = {
    desktop = true,
    dock = true,
    splash = true,
}

local function render_task_text(c, ctpp)
    local name = xml_escape(c.name or "")

    if name == "" then
        name = "untitled"
    end

    if c.minimized then
        return '<span foreground="' .. ctpp.overlay1 .. '">[min] ' .. name .. '</span>'
    end

    if client and c == client.focus then
        return '<span foreground="' .. ctpp.blue .. '"><b>' .. name .. '</b></span>'
    end

    return '<span foreground="' .. ctpp.text .. '">' .. name .. '</span>'
end

local function render_task_tooltip(c)
    local title = c.name or "untitled"
    local app_name = c.class or c.instance
    local lines = { "窗口", "标题：" .. title }

    if app_name and app_name ~= "" then
        lines[#lines + 1] = "应用：" .. app_name
    end

    if c.minimized then
        lines[#lines + 1] = "状态：最小化"
    elseif c.urgent then
        lines[#lines + 1] = "状态：紧急"
    end

    return table.concat(lines, "\n")
end

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function is_regular_task_client(c)
    return c
        and c.valid ~= false
        and not c.skip_taskbar
        and not excluded_task_types[c.type]
end

local function is_current_tag_task_client(c, target_screen)
    local ok, matched = pcall(function()
        return awful.widget.tasklist.filter.currenttags(c, target_screen)
    end)

    return ok and matched == true
end

local function screen_task_filter(c, target_screen)
    return is_regular_task_client(c)
        and not c.minimized
        and not c.hidden
        and is_current_tag_task_client(c, target_screen)
end

local function focus_history_task_client(target_screen)
    if not awful.client
        or not awful.client.focus
        or not awful.client.focus.history
        or not awful.client.focus.history.get then
        return nil
    end

    local ok, candidate = pcall(function()
        return awful.client.focus.history.get(target_screen, 0, function(c)
            return screen_task_filter(c, target_screen)
        end)
    end)

    if ok then
        return candidate
    end

    return nil
end

local function first_current_tag_task_client(target_screen)
    if not client or not client.get then
        return nil
    end

    for _, c in ipairs(client.get()) do
        if screen_task_filter(c, target_screen) then
            return c
        end
    end

    return nil
end

local function screen_task_source(target_screen)
    if not client then
        return {}
    end

    if client.focus and screen_task_filter(client.focus, target_screen) then
        return { client.focus }
    end

    local candidate = focus_history_task_client(target_screen) or first_current_tag_task_client(target_screen)
    if candidate then
        return { candidate }
    end

    return {}
end

local function visible_current_tag_task_count(target_screen)
    if not client or not client.get then
        return nil
    end

    local count = 0
    for _, c in ipairs(client.get()) do
        if is_regular_task_client(c)
            and not c.minimized
            and not c.hidden
            and is_current_tag_task_client(c, target_screen) then
            count = count + 1
        end
    end

    return count
end

local function default_task_title_max_width(screen, compact)
    compact = compact == true
    local screen_width = screen and screen.geometry and screen.geometry.width or 1920
    local ratio = compact and 0.12 or 0.16
    local min_width = compact and 220 or 320
    local max_width = compact and 360 or 640
    local computed_width = math.floor((screen_width * ratio) + 0.5)

    return dpi(clamp(computed_width, min_width, max_width))
end

local function expanded_single_task_title_max_width(screen, compact, available_width)
    local default_width = default_task_title_max_width(screen, compact)
    local screen_width = screen and screen.geometry and screen.geometry.width or 1920
    local fallback_ratio = compact and 0.46 or 0.52
    local fallback_width = dpi(math.floor((screen_width * fallback_ratio) + 0.5))
    local task_chrome_width = dpi(compact and 62 or 74)
    local expanded_width = math.floor(math.max((tonumber(available_width) or fallback_width) - task_chrome_width, 0) + 0.5)

    return math.max(default_width, expanded_width)
end

local function task_title_max_width(screen, config, compact, available_width)
    compact = compact == true
    local visible_task_count = visible_current_tag_task_count(screen)

    if visible_task_count ~= nil and visible_task_count <= 1 then
        return expanded_single_task_title_max_width(screen, compact, available_width)
    end

    return default_task_title_max_width(screen, compact)
end

local function update_task_item(self, c, ctpp, screen, config, compact, available_width)
    local img = self:get_children_by_id("icon_role")[1]
    if img then
        img.forced_width = dpi(20)
        img.forced_height = dpi(20)
    end

    local text_constraint = self:get_children_by_id("text_constraint_role")[1]
    if text_constraint then
        text_constraint.width = task_title_max_width(screen, config, compact, available_width)
        text_constraint.visible = true
    end

    local text = self:get_children_by_id("text_role")[1]
    if text then
        text.markup = render_task_text(c, ctpp)
        text.visible = true
    end

    local focused = client and c == client.focus
    local urgent = c.urgent
    local background = self:get_children_by_id("task_background_role")[1]
    if background then
        background.bg = "#00000000"
    end

    local indicator = self:get_children_by_id("focus_indicator_role")[1]
    if indicator then
        indicator.bg = urgent and ctpp.red or (focused and ctpp.blue or ctpp.overlay0)
    end
end

local function create_tasklist(ctpp, screen, tasklist_buttons, config, compact, available_width)
    compact = compact == true
    local item_spacing = compact and 3 or 5
    local item_h_padding = compact and 5 or 7
    local item_v_padding = compact and 1 or 2

    return awful.widget.tasklist {
        screen = screen,
        source = screen_task_source,
        filter = screen_task_filter,
        buttons = tasklist_buttons,
        layout = {
            spacing = dpi(3),
            layout = wibox.layout.fixed.horizontal,
        },
        widget_template = {
            {
                {
                    {
                        id = "focus_indicator_role",
                        forced_width = dpi(3),
                        widget = wibox.container.background,
                    },
                    {
                        {
                            id = "icon_role",
                            widget = wibox.widget.imagebox,
                        },
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    {
                        {
                            id = "text_role",
                            ellipsize = "end",
                            widget = wibox.widget.textbox,
                        },
                        id = "text_constraint_role",
                        strategy = "max",
                        width = task_title_max_width(screen, config, compact, available_width),
                        widget = wibox.container.constraint,
                    },
                    spacing = item_spacing,
                    layout = wibox.layout.fixed.horizontal,
                },
                left = item_h_padding,
                right = item_h_padding,
                top = item_v_padding,
                bottom = item_v_padding,
                widget = wibox.container.margin,
            },
            id = "task_background_role",
            bg = "#00000000",
            widget = wibox.container.background,
            create_callback = function(self, c)
                self._task_tooltip_text = render_task_tooltip(c)
                if not self._task_tooltip then
                    self._task_tooltip = awful.tooltip {
                        objects = { self },
                        timer_function = function()
                            return self._task_tooltip_text or ""
                        end,
                    }
                end
                update_task_item(self, c, ctpp, screen, config, compact, available_width)
            end,
            update_callback = function(self, c)
                self._task_tooltip_text = render_task_tooltip(c)
                update_task_item(self, c, ctpp, screen, config, compact, available_width)
            end,
        },
    }
end

return {
    create_tasklist = create_tasklist,
    task_title_max_width = task_title_max_width,
    _private = {
        screen_task_filter = screen_task_filter,
        screen_task_source = screen_task_source,
        focus_history_task_client = focus_history_task_client,
        first_current_tag_task_client = first_current_tag_task_client,
        visible_current_tag_task_count = visible_current_tag_task_count,
        default_task_title_max_width = default_task_title_max_width,
        expanded_single_task_title_max_width = expanded_single_task_title_max_width,
        task_title_max_width = task_title_max_width,
    },
}
