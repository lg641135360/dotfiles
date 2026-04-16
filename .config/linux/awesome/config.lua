-- Platform detection and configuration
-- Auto-detects OS, distro, and architecture, returns a config table

local platform = {}

-- Detect OS
platform.os = io.popen("uname -s"):read("*l")
platform.arch = io.popen("uname -m"):read("*l")

-- Detect distro (Linux only)
if platform.os == "Linux" then
    local release = io.open("/etc/os-release", "r")
    if release then
        local content = release:read("*a")
        release:close()
        platform.distro = content:match('ID="?(%w+)"?') or "unknown"
    else
        platform.distro = "unknown"
    end
else
    platform.distro = nil
end

-- Platform-specific settings
local config = {
    -- Theme: all platforms now use Catppuccin
    theme_path = "~/.config/awesome/theme/catppuccin.lua",

    -- Default editor
    editor = os.getenv("EDITOR") or "nvim",

    -- Menu style: "freedesktop" or "basic"
    menu_style = (platform.os == "Linux" and platform.distro == "ubuntu") and "freedesktop" or "basic",

    -- Volume widget: enabled on systems with pulseaudio/pipewire
    has_volume = (platform.os == "Linux" and platform.distro == "ubuntu"),

    -- Network interface pattern
    net_interfaces = (platform.os == "Linux" and platform.distro == "arch")
        and "wlan0|eth0|enp|wlp"
        or "wlan0|eth0|enp",

    -- Date format
    date_format = " %a %m月%d日 %H:%M ",
}

return config, platform
