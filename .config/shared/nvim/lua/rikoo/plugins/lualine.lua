-- ~/.config/nvim/lua/rikoo/plugins/lualine.lua
-- lualine.nvim: 快速美观的状态栏
-- 显示模式、文件信息、位置等

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- 可选，用于显示图标
  config = function()
    require("lualine").setup({
      options = {
        theme = "auto",      -- 自动检测配色方案
        section_separators = "", -- 保持简洁风格
        component_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end,
}

