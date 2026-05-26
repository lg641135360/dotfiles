local M = {
    -- Match lists consumed by a single rule_any entry for floating windows.
    floating_instances = {
        "copyq",
        "pinentry",
    },
    floating_classes = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "MessageWin",
        "Sxiv",
        "Tor Browser",
        "Wpa_gui",
        "veromix",
        "xtightvncviewer",
        "Pot",
    },
    floating_names = {
        "Event Tester",
    },
    floating_roles = {
        "AlarmWindow",
        "ConfigManager",
        "pop-up",
    },

    -- Class list for the fallback titlebar rule; ordinary utility windows stay titlebar-free.
    fallback_titlebar_classes = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "MessageWin",
        "Pot",
        "Wpa_gui",
        "veromix",
        "xtightvncviewer",
    },

    semantic_tags = {
        {
            key = "dev",
            name = "开发",
            icon = "󰇩 ",
        },
        {
            key = "browser",
            name = "浏览器",
            icon = "󰓠 ",
        },
        {
            key = "docs",
            name = "文档",
            icon = " ",
        },
        {
            key = "chat",
            name = "沟通",
            icon = "󰠮 ",
        },
        {
            key = "misc",
            name = "杂项",
            icon = " ",
        },
    },

    browser_classes = {
        "firefox",
        "zen-browser",
        "google-chrome",
        "chromium",
        "chromium-browser",
        "microsoft-edge",
        "brave-browser",
        "vivaldi-stable",
    },

    -- Complete awful.rules.rules entries appended after the base rules.
    extra_rules = {
        {
            rule = { class = "tblive", type = "utility" },
            properties = {
                floating = true,
                skip_taskbar = true,
            },
        },
    },
}

return M
