local awful = require("awful")
local beautiful = require("beautiful")
local policies = require("client.policies")

local M = {}

function M.setup(args)
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
        table.unpack(policies.extra_rules),
    }
end

return M
