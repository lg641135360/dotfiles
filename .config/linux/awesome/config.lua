-- Platform detection and configuration
-- Auto-detects OS, distro, and architecture, returns a config table

local platform = {}

local function read_command_output(command)
    local handle = io.popen(command)
    if not handle then
        return nil
    end

    local output = handle:read("*l")
    handle:close()
    return output
end

local function command_exists(command)
    local handle = io.popen("command -v " .. command .. " >/dev/null 2>&1 && printf yes || printf no")
    if not handle then
        return false
    end

    local output = handle:read("*l")
    handle:close()
    return output == "yes"
end

-- Detect OS
platform.os = read_command_output("uname -s")
platform.arch = read_command_output("uname -m")

-- Detect distro (Linux only)
if platform.os == "Linux" then
    local release = io.open("/etc/os-release", "r")
    if release then
        local content = release:read("*a")
        release:close()
        platform.distro = content:match('ID="?([%w%-_]+)"?') or "unknown"
    else
        platform.distro = "unknown"
    end
else
    platform.distro = nil
end

-- Platform-specific settings
local brightness_override = os.getenv("AWESOME_HAS_BRIGHTNESS")

local config = {
    -- Theme: all platforms now use Catppuccin
    theme_path = "~/.config/awesome/theme/catppuccin.lua",

    -- Default editor
    editor = os.getenv("EDITOR") or "nvim",

    -- Menu style: "auto" (capability detection) or "basic"
    menu_style = "auto",

    -- Volume widget: enabled on systems with pulseaudio/pipewire command surface
    has_volume = (platform.os == "Linux" and command_exists("pactl")),

    -- Brightness widget: default to Linux aarch64/arm64, with explicit env override for tests and special hosts
    has_brightness = brightness_override == "1" or (brightness_override ~= "0" and platform.os == "Linux" and (platform.arch == "aarch64" or platform.arch == "arm64")),

    -- Network interface pattern
    net_interfaces = "wlan0|eth0|enp|wlp",

    -- Date format
    date_format = " %a %m月%d日 %H:%M ",
    compact_date_format = " %m/%d %H:%M ",
    compact_wibar_max_width = 3000,
    compact_wibar_max_diagonal_inches = 15,
}

return config, platform
