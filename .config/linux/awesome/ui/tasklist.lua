local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi

local M = {}

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

local function current_tag_client_count(screen)
    if not screen or not screen.selected_tag then
        return 0
    end

    return #screen.selected_tag:clients()
end

local function task_density_tier(screen)
    local client_count = current_tag_client_count(screen)

    if client_count >= 7 then
        return "tight"
    end

    if client_count >= 4 then
        return "compact"
    end

    return "relaxed"
end

local function task_title_display_mode(screen, available_width, config, compact)
    local client_count = current_tag_client_count(screen)
    if client_count < 5 then
        return "text"
    end

    local budget_width = math.max(available_width or 0, 0)
    if budget_width <= 0 then
        return client_count >= 8 and "icon_only" or "text"
    end

    local average_width = math.floor((budget_width / client_count) + 0.5)
    local text_threshold = task_title_max_width(screen, config, compact)
    if average_width < text_threshold then
        return "icon_only"
    end

    return "text"
end

local function task_overflow_indicator_text(hidden_count)
    return "+" .. hidden_count
end

local function task_overflow_tooltip_text(hidden_count)
    local overflow_text = task_overflow_indicator_text(hidden_count)
    return overflow_text .. "\n还有" .. hidden_count .. " 个窗口未显示"
end

local function task_title_max_width(screen, config, compact)
    compact = compact == true
    local density = task_density_tier(screen)
    local screen_width = screen and screen.geometry and screen.geometry.width or 1920
    local ratio = compact and 0.12 or 0.16
    local min_width = compact and 220 or 320
    local max_width = compact and 360 or 640

    if density == "tight" then
        ratio = compact and 0.09 or 0.12
        min_width = compact and 160 or 220
        max_width = compact and 260 or 360
    elseif density == "compact" then
        ratio = compact and 0.1 or 0.14
        min_width = compact and 190 or 260
        max_width = compact and 320 or 480
    end

    local computed_width = math.floor((screen_width * ratio) + 0.5)
    return dpi(clamp(computed_width, min_width, max_width))
end

local function measured_task_slot_width(screen, available_width)
    if not screen or not screen._omx_wibar_probe or not screen._omx_wibar_probe.last then
        return nil
    end

    local probe = screen._omx_wibar_probe.last
    local client_count = current_tag_client_count(screen)
    if client_count <= 0 then
        return nil
    end

    local fit_width = math.min(probe.tasklist_width or 0, math.max(available_width or 0, 0)) / client_count
    if fit_width <= 0 then
        return nil
    end

    return math.max(math.floor(fit_width + 0.5), 1)
end

local function estimated_visible_task_slots(screen, available_width)
    local budget_width = math.max(available_width or 0, 0)
    local measured_width = measured_task_slot_width(screen, budget_width)
    local fallback_width = current_tag_client_count(screen) >= 8 and 36 or 220
    local slot_width = measured_width or fallback_width

    if slot_width <= 0 then
        return 0
    end

    return math.max(math.floor(budget_width / slot_width), 0)
end

local function hidden_task_count(screen, available_width)
    local client_count = current_tag_client_count(screen)
    local visible_slots = estimated_visible_task_slots(screen, available_width)
    return math.max(client_count - visible_slots, 0)
end

local function update_task_item(self, c, ctpp, screen, config, compact, available_width)
    local display_mode = task_title_display_mode(screen, available_width, config, compact)
    local img = self:get_children_by_id("icon_role")[1]
    if img then
        img.forced_width = dpi(20)
        img.forced_height = dpi(20)
    end

    local text_constraint = self:get_children_by_id("text_constraint_role")[1]
    if text_constraint then
        text_constraint.width = task_title_max_width(screen, config, compact)
        text_constraint.visible = display_mode ~= "icon_only"
    end

    local text = self:get_children_by_id("text_role")[1]
    if text then
        text.markup = render_task_text(c, ctpp)
        text.visible = display_mode ~= "icon_only"
    end

    local focused = client and c == client.focus
    local urgent = c.urgent
    local background = self:get_children_by_id("background_role")[1]
    if background then
        background.bg = focused and ctpp.surface0 or ctpp.base
    end

    local indicator = self:get_children_by_id("focus_indicator_role")[1]
    if indicator then
        indicator.bg = urgent and ctpp.red or (focused and ctpp.blue or ctpp.base)
    end
end

function M.create_overflow_indicator(ctpp, screen)
    local overflow_indicator = wibox.widget {
        {
            {
                id = "task_overflow_text_role",
                widget = wibox.widget.textbox,
            },
            left = dpi(4),
            right = dpi(4),
            top = dpi(1),
            bottom = dpi(1),
            widget = wibox.container.margin,
        },
        bg = ctpp.base,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background,
    }

    overflow_indicator:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.menu.client_list({ theme = { width = 250 } })
        end),
        awful.button({}, 3, function()
            awful.menu.client_list({ theme = { width = 250 } })
        end)
    ))

    awful.tooltip {
        objects = { overflow_indicator },
        timer_function = function()
            return overflow_indicator._tooltip_text or ""
        end,
    }

    function overflow_indicator:update(available_width)
        local hidden_count = hidden_task_count(screen, available_width)
        local overflow_text = task_overflow_indicator_text(hidden_count)
        local text = self:get_children_by_id("task_overflow_text_role")[1]
        if text then
            text.markup = "<span foreground='" .. ctpp.subtext1 .. "'><b>" .. overflow_text .. "</b></span>"
        end
        self._tooltip_text = task_overflow_tooltip_text(hidden_count)
        self.visible = hidden_count > 0
    end

    overflow_indicator:update(0)
    return overflow_indicator
end

local function create_tasklist(ctpp, screen, tasklist_buttons, config, compact)
    compact = compact == true
    local density = task_density_tier(screen)
    local item_spacing = compact and 3 or 5
    local item_h_padding = compact and 5 or 7
    local item_v_padding = compact and 1 or 2

    if density == "tight" then
        item_spacing = compact and 2 or 3
        item_h_padding = compact and 4 or 5
    elseif density == "compact" then
        item_spacing = compact and 3 or 4
        item_h_padding = compact and 5 or 6
    end

    return awful.widget.tasklist {
        screen = screen,
        filter = awful.widget.tasklist.filter.currenttags,
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
            id = "background_role",
            bg = ctpp.base,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, dpi(8))
            end,
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
            local current_available_width = math.max((screen and screen._omx_task_available_width) or 0, 0)
                update_task_item(self, c, ctpp, screen, config, compact, current_available_width)
            end,
            update_callback = function(self, c)
                self._task_tooltip_text = render_task_tooltip(c)
            local current_available_width = math.max((screen and screen._omx_task_available_width) or 0, 0)
                update_task_item(self, c, ctpp, screen, config, compact, current_available_width)
            end,
        },
    }
end

return {
    create_tasklist = create_tasklist,
    create_overflow_indicator = M.create_overflow_indicator,
    task_title_max_width = task_title_max_width,
    _private = {
        task_title_max_width = task_title_max_width,
    },
}
