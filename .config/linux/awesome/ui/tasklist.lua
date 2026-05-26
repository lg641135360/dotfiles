local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local xml_escape = gears.string.xml_escape

local function render_task_text(c, ctpp)
    local name = xml_escape(c.name or "")

    if name == "" then
        name = "untitled"
    end

    if c.minimized then
        return '<span color="' .. ctpp.overlay2 .. '">[min] ' .. name .. '</span>'
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

local function focused_task_filter(c)
    return client and c == client.focus
end

local function focused_task_source(target_screen)
    if not client or not client.focus then
        return {}
    end

    if not awful.widget.tasklist.filter.currenttags(client.focus, target_screen) then
        return {}
    end

    return { client.focus }
end

local function task_title_max_width(screen, config, compact)
    compact = compact == true
    local screen_width = screen and screen.geometry and screen.geometry.width or 1920
    local ratio = compact and 0.12 or 0.16
    local min_width = compact and 220 or 320
    local max_width = compact and 360 or 640
    local computed_width = math.floor((screen_width * ratio) + 0.5)

    return dpi(clamp(computed_width, min_width, max_width))
end

local function update_task_item(self, c, ctpp, screen, config, compact)
    local img = self:get_children_by_id("icon_role")[1]
    if img then
        img.forced_width = dpi(20)
        img.forced_height = dpi(20)
    end

    local text_constraint = self:get_children_by_id("text_constraint_role")[1]
    if text_constraint then
        text_constraint.width = task_title_max_width(screen, config, compact)
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
        indicator.bg = urgent and ctpp.red or (focused and ctpp.blue or ctpp.base)
    end
end

local function create_tasklist(ctpp, screen, tasklist_buttons, config, compact)
    compact = compact == true
    local item_spacing = compact and 3 or 5
    local item_h_padding = compact and 5 or 7
    local item_v_padding = compact and 1 or 2

    return awful.widget.tasklist {
        screen = screen,
        source = focused_task_source,
        filter = focused_task_filter,
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
                        width = task_title_max_width(screen, config, compact),
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
                update_task_item(self, c, ctpp, screen, config, compact)
            end,
            update_callback = function(self, c)
                self._task_tooltip_text = render_task_tooltip(c)
                update_task_item(self, c, ctpp, screen, config, compact)
            end,
        },
    }
end

return {
    create_tasklist = create_tasklist,
    task_title_max_width = task_title_max_width,
    _private = {
        focused_task_filter = focused_task_filter,
        focused_task_source = focused_task_source,
        task_title_max_width = task_title_max_width,
    },
}
