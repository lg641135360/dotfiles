-- ~/.config/nvim/lua/rikoo/plugins/lualine.lua
-- lualine.nvim: 快速美观的状态栏

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "tokyonight",
        section_separators = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
        globalstatus = true, -- 单一全局状态栏
      },
      sections = {
        lualine_a = { { "mode", fmt = function(str) return str:sub(1,1) end } }, -- 只显示首字母
        lualine_b = { 
          { "branch", icon = "" },
          { "diff", symbols = { added = " ", modified = " ", removed = " " } },
        },
        lualine_c = { 
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[未命名]" } }
        },
        lualine_x = { 
          { "diagnostics", sources = { "nvim_diagnostic" }, symbols = { error = " ", warn = " ", info = " ", hint = " " } },
          { "filetype", icon_only = true },
        },
        lualine_y = { 
          { "progress", separator = "" },
          { "location" }
        },
        lualine_z = {
          function()
            return " " .. os.date("%H:%M")
          end,
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    })
  end,
}

