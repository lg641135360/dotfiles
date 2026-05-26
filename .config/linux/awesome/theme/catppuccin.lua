-- Catppuccin Mocha Theme for AwesomeWM
-- https://github.com/catppuccin/catppuccin

local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local gears = require("gears")

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()

-- Catppuccin Mocha Palette
local palette = {
    -- Base colors
    rosewater = "#f5e0dc",
    flamingo  = "#f2cdcd",
    pink      = "#f5c2e7",
    mauve     = "#cba6f7",
    red       = "#f38ba8",
    maroon    = "#eba0ac",
    peach     = "#fab387",
    yellow    = "#f9e2af",
    green     = "#a6e3a1",
    teal      = "#94e2d5",
    sky       = "#89dceb",
    sapphire  = "#74c7ec",
    blue      = "#89b4fa",
    lavender  = "#b4befe",
    text      = "#cdd6f4",
    subtext1  = "#bac2de",
    subtext0  = "#a6adc8",
    overlay2  = "#9399b2",
    overlay1  = "#7f849c",
    overlay0  = "#6c7086",
    surface2  = "#585b70",
    surface1  = "#45475a",
    surface0  = "#313244",
    base      = "#1e1e2e",
    mantle    = "#181825",
    crust     = "#11111b",
}

local theme = {}

-- Fonts
theme.font          = "Maple Mono NF CN 11"
theme.menu_font     = "Maple Mono NF CN 11"
theme.notification_font = "Maple Mono NF CN 11"
theme.hotkeys_font  = "Maple Mono NF CN 12"
theme.hotkeys_description_font = "Maple Mono NF CN 11"

-- Background colors
theme.bg_normal     = palette.base
theme.bg_focus      = palette.base  -- Same as bg_normal, no highlight on selected items
theme.bg_urgent     = palette.red
theme.bg_minimize   = palette.surface1
theme.bg_systray    = theme.bg_normal

-- Foreground colors
theme.fg_normal     = palette.text
theme.fg_focus      = palette.blue
theme.fg_urgent     = palette.red
theme.fg_minimize   = palette.subtext0

-- Window borders
theme.useless_gap   = dpi(8)
theme.border_width  = dpi(2)
theme.border_normal = palette.surface0
theme.border_focus  = palette.blue
theme.border_marked = palette.peach
theme.border_radius = dpi(12)

-- Fallback titlebar styling (only for select floating utility/config windows)
theme.titlebar_size = dpi(24)
theme.titlebar_radius = dpi(8)
theme.titlebar_spacing = dpi(4)
theme.titlebar_side_padding = dpi(6)
theme.titlebar_section_padding = dpi(4)
theme.titlebar_bg_normal = palette.surface0
theme.titlebar_bg_focus = palette.surface1
theme.titlebar_fg_normal = palette.subtext0
theme.titlebar_fg_focus = palette.text
theme.titlebar_border_color = palette.overlay0
theme.titlebar_border_color_focus = palette.surface2
theme.titlebar_border_width = dpi(1)
theme.titlebar_font = "Maple Mono NF CN 10.5"
theme.titlebar_button_font = "Maple Mono NF CN 10.5"
theme.titlebar_button_radius = dpi(5)
theme.titlebar_button_padding_x = dpi(5)
theme.titlebar_button_padding_y = dpi(1)
theme.titlebar_button_bg_normal = palette.mantle
theme.titlebar_button_bg_active = palette.surface0
theme.titlebar_button_bg_close = palette.mantle
theme.titlebar_button_fg_normal = palette.subtext0
theme.titlebar_button_fg_active = palette.blue
theme.titlebar_button_fg_close = palette.red

-- Taglist configuration
theme.taglist_spacing = dpi(8)
-- No background color change on selected workspace - only icon color changes
-- theme.taglist_bg_focus = palette.blue  -- Commented out for original behavior
theme.taglist_fg_focus = palette.blue
theme.taglist_fg_occupied = palette.lavender

-- Generate taglist squares for occupied indicator
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
    taglist_square_size, palette.blue
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    taglist_square_size, palette.blue
)

-- Tasklist configuration
theme.tasklist_bg_normal = palette.base
theme.tasklist_bg_focus = palette.base
theme.tasklist_bg_urgent = palette.base
theme.tasklist_fg_normal = palette.subtext0
theme.tasklist_fg_focus = palette.blue
theme.tasklist_fg_urgent = palette.red
theme.tasklist_spacing = dpi(4)

-- Notification styling
theme.notification_bg = palette.base
theme.notification_fg = palette.text
theme.notification_border_width = dpi(2)
theme.notification_border_color = palette.blue
theme.notification_opacity = 0.95
theme.notification_shape = function(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, dpi(10))
end
theme.notification_margin = dpi(10)

-- Menu styling
theme.menu_submenu_icon = themes_path.."default/submenu.png"
theme.menu_height = dpi(35)
theme.menu_width  = dpi(200)
theme.menu_bg_normal = palette.mantle
theme.menu_bg_focus = palette.surface0
theme.menu_fg_normal = palette.subtext1
theme.menu_fg_focus = palette.blue
theme.menu_border_color = palette.overlay0
theme.menu_border_width = dpi(1)
theme.menu_shape = function(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, dpi(8))
end

-- Prompt styling
theme.prompt_bg_normal = palette.base
theme.prompt_bg_focus = palette.surface0
theme.prompt_fg_normal = palette.text
theme.prompt_fg_focus = palette.blue
theme.prompt_border_color = palette.surface1
theme.prompt_shape = function(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, dpi(8))
end

-- Tooltip styling
theme.tooltip_bg = palette.mantle
theme.tooltip_fg = palette.text
theme.tooltip_border_color = palette.overlay0
theme.tooltip_border_width = dpi(1)
theme.tooltip_shape = function(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, dpi(8))
end

-- Hotkeys styling
theme.hotkeys_bg = palette.crust
theme.hotkeys_fg = palette.text
theme.hotkeys_border_color = palette.surface1
theme.hotkeys_border_width = dpi(2)
theme.hotkeys_shape = function(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, dpi(12))
end

-- Titlebar buttons (using default assets)
theme.titlebar_close_button_normal = themes_path.."default/titlebar/close_normal.png"
theme.titlebar_close_button_focus  = themes_path.."default/titlebar/close_focus.png"
theme.titlebar_minimize_button_normal = themes_path.."default/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = themes_path.."default/titlebar/minimize_focus.png"
theme.titlebar_ontop_button_normal_inactive = themes_path.."default/titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive  = themes_path.."default/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active = themes_path.."default/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active  = themes_path.."default/titlebar/ontop_focus_active.png"
theme.titlebar_sticky_button_normal_inactive = themes_path.."default/titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive  = themes_path.."default/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active = themes_path.."default/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active  = themes_path.."default/titlebar/sticky_focus_active.png"
theme.titlebar_floating_button_normal_inactive = themes_path.."default/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive  = themes_path.."default/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active = themes_path.."default/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active  = themes_path.."default/titlebar/floating_focus_active.png"
theme.titlebar_maximized_button_normal_inactive = themes_path.."default/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = themes_path.."default/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = themes_path.."default/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active  = themes_path.."default/titlebar/maximized_focus_active.png"

-- Layout icons
theme.layout_fairh = themes_path.."default/layouts/fairhw.png"
theme.layout_fairv = themes_path.."default/layouts/fairvw.png"
theme.layout_floating  = themes_path.."default/layouts/floatingw.png"
theme.layout_magnifier = themes_path.."default/layouts/magnifierw.png"
theme.layout_max = themes_path.."default/layouts/maxw.png"
theme.layout_fullscreen = themes_path.."default/layouts/fullscreenw.png"
theme.layout_tilebottom = themes_path.."default/layouts/tilebottomw.png"
theme.layout_tileleft   = themes_path.."default/layouts/tileleftw.png"
theme.layout_tile = themes_path.."default/layouts/tilew.png"
theme.layout_tiletop = themes_path.."default/layouts/tiletopw.png"
theme.layout_spiral  = themes_path.."default/layouts/spiralw.png"
theme.layout_dwindle = themes_path.."default/layouts/dwindlew.png"
theme.layout_cornernw = themes_path.."default/layouts/cornernww.png"
theme.layout_cornerne = themes_path.."default/layouts/cornernew.png"
theme.layout_cornersw = themes_path.."default/layouts/cornersww.png"
theme.layout_cornerse = themes_path.."default/layouts/cornersew.png"

-- Awesome icon
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height, palette.lavender, palette.text
)

-- Icon theme
theme.icon_theme = nil

-- Custom colors for widgets (export for use in rc.lua)
theme.ctpp = palette  -- Export full palette for custom widgets

-- Wallpaper is managed externally by autostart/feh.

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
