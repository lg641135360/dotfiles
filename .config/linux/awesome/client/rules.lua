local awful = require("awful")
local beautiful = require("beautiful")
local policies = require("client.policies")

local M = {}

local function semantic_tag_icons()
    local icons = {}

    for _, definition in ipairs(policies.semantic_tags or {}) do
        icons[#icons + 1] = definition.icon
    end

    return icons
end

local function semantic_tag_index(key)
    for index, definition in ipairs(policies.semantic_tags or {}) do
        if definition.key == key then
            return index
        end
    end

    return nil
end

local function tag_by_index(target_screen, index)
    if not target_screen or not target_screen.tags or not index then
        return nil
    end

    return target_screen.tags[index]
end

function M.setup(args)
    local browser_tag_index = semantic_tag_index("browser")

    awful.rules.rules = {
        {
            rule = {},
            properties = {
                border_width = beautiful.border_width,
                border_color = beautiful.border_normal,
                focus = awful.client.focus.filter,
                raise = true,
                keys = args.clientkeys,
                buttons = args.clientbuttons,
                screen = awful.screen.preferred,
                placement = awful.placement.no_overlap + awful.placement.no_offscreen,
                size_hints_honor = false,
                titlebars_enabled = false,
            },
        },
        {
            rule_any = {
                instance = policies.floating_instances,
                class = policies.floating_classes,
                name = policies.floating_names,
                role = policies.floating_roles,
            },
            properties = { floating = true },
        },
        {
            rule_any = {
                class = policies.fallback_titlebar_classes,
            },
            except_any = {
                class = {
                    "tblive",
                },
            },
            properties = { titlebars_enabled = true },
        },
        {
            rule_any = {
                class = policies.browser_classes,
            },
            properties = {
                tag = tag_by_index(awful.screen.preferred(), browser_tag_index),
                switch_to_tags = false,
            },
        },
        table.unpack(policies.extra_rules),
    }
end

M._private = {
    semantic_tag_icons = semantic_tag_icons,
    semantic_tag_index = semantic_tag_index,
    tag_by_index = tag_by_index,
}

return M
