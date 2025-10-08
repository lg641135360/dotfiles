-- ~/.config/nvim/lua/rikoo/plugins/comment.lua
-- Comment.nvim: easy commenting
-- Keys:
--   gcc  -> toggle comment on current line
--   gc   -> toggle comment on selection (visual mode)

return {
  "numToStr/Comment.nvim",
  config = function()
    require("Comment").setup()
  end,
}

