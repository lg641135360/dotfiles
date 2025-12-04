-- ~/.config/nvim/lua/rikoo/plugins/surround.lua
-- nvim-surround: 添加/修改/删除环绕符号
-- 示例:
--   ysiw"  -> 给单词添加双引号
--   cs"'   -> 将双引号改为单引号
--   ds"    -> 删除双引号
--   可视模式: 选中文本 + S) -> 用括号环绕

return {
  "kylechui/nvim-surround",
  version = "*", -- 使用最新稳定版
  event = "VeryLazy", -- 延迟加载
  config = function()
    require("nvim-surround").setup({})
  end,
}

