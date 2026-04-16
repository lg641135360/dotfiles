-- Volume widget using pactl
-- Only used on systems with pulseaudio/pipewire

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local function create_volume_widget()
    local ctpp = beautiful.ctpp

    local vol_widget = wibox.widget.textbox()
    vol_widget:set_markup("<span foreground='" .. ctpp.yellow .. "'>VOL</span><span foreground='" .. ctpp.text .. "'> --%</span>")

    local function update_volume()
        awful.spawn.easy_async_with_shell("pactl get-sink-volume @DEFAULT_SINK@ | grep -oE '[0-9]+%' | head -1", function(out)
            local vol = out:gsub("[\n%%]", "")
            if vol and vol ~= "" then
                vol_widget:set_markup("<span foreground='" .. ctpp.yellow .. "'>VOL</span><span foreground='" .. ctpp.text .. "'> " .. vol .. "%</span>")
            else
                vol_widget:set_markup("<span foreground='" .. ctpp.yellow .. "'>VOL</span><span foreground='" .. ctpp.text .. "'> --%</span>")
            end
        end)
    end

    update_volume()

    vol_widget:buttons(gears.table.join(
        awful.button({ }, 4, function()
            awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ +5%")
            gears.timer.start_new(0.2, function()
                update_volume()
                return false
            end)
        end),
        awful.button({ }, 5, function()
            awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ -5%")
            gears.timer.start_new(0.2, function()
                update_volume()
                return false
            end)
        end),
        awful.button({ }, 1, function()
            awful.spawn.with_shell("pactl set-sink-mute @DEFAULT_SINK@ toggle")
            gears.timer.start_new(0.2, function()
                update_volume()
                return false
            end)
        end)
    ))

    return vol_widget, update_volume
end

return {
    create = create_volume_widget,
}
