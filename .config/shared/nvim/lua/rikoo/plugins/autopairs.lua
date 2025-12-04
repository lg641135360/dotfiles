-- ~/.config/nvim/lua/rikoo/plugins/autopairs.lua
-- nvim-autopairs: 自动补全括号和引号
-- 示例:
--   输入 (  -> 自动补全 )
--   输入 " -> 自动补全 "

return {
  "windwp/nvim-autopairs",
  event = "InsertEnter", -- 进入插入模式时才加载
  config = function()
    require("nvim-autopairs").setup({})
  end,
}

