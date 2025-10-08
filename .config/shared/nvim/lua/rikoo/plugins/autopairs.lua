-- ~/.config/nvim/lua/rikoo/plugins/autopairs.lua
-- nvim-autopairs: auto insert matching brackets/quotes
-- Example:
--   type (  -> auto insert )
--   type " -> auto insert "

return {
  "windwp/nvim-autopairs",
  event = "InsertEnter", -- load only when entering insert mode
  config = function()
    require("nvim-autopairs").setup({})
  end,
}

