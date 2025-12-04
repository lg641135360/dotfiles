-- ~/.config/nvim/lua/rikoo/plugins/comment.lua
-- Comment.nvim: 快速注释代码
-- 快捷键:
--   gcc  -> 切换当前行注释
--   gc   -> 切换选中内容注释 (可视模式)
--   gbc  -> 切换块注释

return {
  "numToStr/Comment.nvim",
  config = function()
    require("Comment").setup()
  end,
}

