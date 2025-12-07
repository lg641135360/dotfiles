-- ~/.config/nvim/lua/rikoo/plugins/smooth-scroll.lua
-- mini.animate: 平滑滚动和光标动画

return {
  "echasnovski/mini.animate",
  event = "VeryLazy",
  config = function()
    require("mini.animate").setup({
      cursor = {
        enable = false, -- 禁用光标动画，可能会卡
      },
      scroll = {
        enable = true,
        timing = function(_, n) return 15 * n end, -- 平滑滚动速度
      },
      resize = {
        enable = false,
      },
      open = {
        enable = false,
      },
      close = {
        enable = false,
      },
    })
  end,
}
