-- ~/.config/nvim/lua/rikoo/plugins/indent.lua
-- indent-blankline: 显示缩进参考线
-- 帮助可视化代码结构和嵌套块

return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl", -- 新版 API 名称
  opts = {
    indent = { char = "│" }, -- 缩进线字符
    scope = { enabled = true }, -- 高亮当前作用域
  },
}

