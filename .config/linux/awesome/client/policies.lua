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
            description = "终端、编辑器、调试与构建任务。",
        },
        {
            key = "browser",
            name = "浏览器",
            icon = "󰓠 ",
            description = "浏览器、网页检索与在线工作流。",
        },
        {
            key = "docs",
            name = "文档",
            icon = " ",
            description = "资料阅读、PDF、笔记与文档整理。",
        },
        {
            key = "chat",
            name = "沟通",
            icon = "󰠮 ",
            description = "IM、会议与即时协作。",
        },
        {
            key = "misc",
            name = "杂项",
            icon = " ",
            description = "临时工具、文件处理与未归类窗口。",
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
